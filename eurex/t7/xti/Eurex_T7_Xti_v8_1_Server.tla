--------------------- MODULE Eurex_T7_Xti_v8_1_Server ----------------------
(***************************************************************************)
(* Eurex Exchange Cash Enhanced Trading Interface v8.1                     *)
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
(* Note: Best Quote Execution Report fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Best Quote Response fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Alignment Padding pads to a 8 byte boundary: it is read as the    *)
(* bytes left to the end of the frame, and the frame's length is trusted   *)
(* to keep that boundary.                                                  *)
(*                                                                         *)
(* Note: Broadcast Error Notification fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Cross Request Response fills what is left of the frame Body Len   *)
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
(* Note: Extended Deletion Report fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Forced Logout Notification fills what is left of the frame Body   *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Forced User Logout Notification fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Heartbeat Notification fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Inquire Enrichment Rule Id List Response fills what is left of    *)
(* the frame Body Len states, which is what it is read from.               *)
(*                                                                         *)
(* Note: Inquire Session List Response fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Inquire User Response fills what is left of the frame Body Len    *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Issuer Notification fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Issuer Security State Change Response fills what is left of the   *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Legal Notification Broadcast fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
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
(* Note: Party Action Report fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Party Entitlements Update Report fills what is left of the frame  *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Quote Activation Notification fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Quote Activation Response fills what is left of the frame Body    *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Quote Execution Report fills what is left of the frame Body Len   *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Rfq Broadcast fills what is left of the frame Body Len states,    *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Rfq Reject Notification fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Rfq Response fills what is left of the frame Body Len states,     *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Rfq Specialist Broadcast fills what is left of the frame Body Len *)
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
(* Note: Service Availability Broadcast fills what is left of the frame    *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Service Availability Market Broadcast fills what is left of the   *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Specialist Delete All Order Broadcast fills what is left of the   *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Specialist Instrument Event Notification fills what is left of    *)
(* the frame Body Len states, which is what it is read from.               *)
(*                                                                         *)
(* Note: Specialist Order Book Notification fills what is left of the      *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Specialist Rfq Reply Notification fills what is left of the frame *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Specialist Rfq Reply Response fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Specialist Security State Change Response fills what is left of   *)
(* the frame Body Len states, which is what it is read from.               *)
(*                                                                         *)
(* Note: Subscribe Response fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Tes Approve Broadcast fills what is left of the frame Body Len    *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Tes Broadcast fills what is left of the frame Body Len states,    *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Tes Delete Broadcast fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Tes Execution Broadcast fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Tes Response fills what is left of the frame Body Len states,     *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Tes Trade Broadcast fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Tes Trading Session Status Broadcast fills what is left of the    *)
(* frame Body Len states, which is what it is read from.                   *)
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
(* Note: Trading Session Status Broadcast fills what is left of the frame  *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Trailing Stop Update Notification fills what is left of the frame *)
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
(* Note: Xetra En Light Create Deal Notification fills what is left of the *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Xetra En Light Deal Response fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Xetra En Light Negotiation Notification fills what is left of the *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Xetra En Light Negotiation Requester Notification fills what is   *)
(* left of the frame Body Len states, which is what it is read from.       *)
(*                                                                         *)
(* Note: Xetra En Light Negotiation Status Notification fills what is left *)
(* of the frame Body Len states, which is what it is read from.            *)
(*                                                                         *)
(* Note: Xetra En Light Open Negotiation Notification fills what is left   *)
(* of the frame Body Len states, which is what it is read from.            *)
(*                                                                         *)
(* Note: Xetra En Light Open Negotiation Requester Notification fills what *)
(* is left of the frame Body Len states, which is what it is read from.    *)
(*                                                                         *)
(* Note: Xetra En Light Quote Notification fills what is left of the frame *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Xetra En Light Quote Requester Notification fills what is left of *)
(* the frame Body Len states, which is what it is read from.               *)
(*                                                                         *)
(* Note: Xetra En Light Quote Response fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Xetra En Light Status Broadcast fills what is left of the frame   *)
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
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Best Quote Execution Report: 122 bytes                                  *)
(***************************************************************************)

BestQuoteExecutionReport ==
    [ pad2              : Sample(2),
      rbcHeaderMeComp   : RbcHeaderMeComp,
      execId            : Sample(8),
      quoteMsgId        : Sample(8),
      securityId        : Sample(8),
      quoteEventPx      : Sample(8),
      quoteEventQty     : Sample(8),
      reservedSize      : Sample(8),
      marketSegmentId   : Sample(4),
      quoteEventMatchId : Sample(4),
      quoteEventExecId  : Sample(4),
      quoteEventType    : Sample(1),
      quoteEventSide    : Sample(1),
      pad2v2            : Sample(2) ]

EncodeBestQuoteExecutionReport(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp(message.rbcHeaderMeComp)
        \o message.execId
        \o message.quoteMsgId
        \o message.securityId
        \o message.quoteEventPx
        \o message.quoteEventQty
        \o message.reservedSize
        \o message.marketSegmentId
        \o message.quoteEventMatchId
        \o message.quoteEventExecId
        \o message.quoteEventType
        \o message.quoteEventSide
        \o message.pad2v2

DecodeBestQuoteExecutionReport(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET execId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET quoteMsgId == ReadBytes(execId.rest, 8) IN IF ~quoteMsgId.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteMsgId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteEventPx == ReadBytes(securityId.rest, 8) IN IF ~quoteEventPx.ok THEN Fail ELSE
    LET quoteEventQty == ReadBytes(quoteEventPx.rest, 8) IN IF ~quoteEventQty.ok THEN Fail ELSE
    LET reservedSize == ReadBytes(quoteEventQty.rest, 8) IN IF ~reservedSize.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(reservedSize.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET quoteEventMatchId == ReadBytes(marketSegmentId.rest, 4) IN IF ~quoteEventMatchId.ok THEN Fail ELSE
    LET quoteEventExecId == ReadBytes(quoteEventMatchId.rest, 4) IN IF ~quoteEventExecId.ok THEN Fail ELSE
    LET quoteEventType == ReadBytes(quoteEventExecId.rest, 1) IN IF ~quoteEventType.ok THEN Fail ELSE
    LET quoteEventSide == ReadBytes(quoteEventType.rest, 1) IN IF ~quoteEventSide.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(quoteEventSide.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ pad2              |-> pad2.value,
         rbcHeaderMeComp   |-> rbcHeaderMeComp.value,
         execId            |-> execId.value,
         quoteMsgId        |-> quoteMsgId.value,
         securityId        |-> securityId.value,
         quoteEventPx      |-> quoteEventPx.value,
         quoteEventQty     |-> quoteEventQty.value,
         reservedSize      |-> reservedSize.value,
         marketSegmentId   |-> marketSegmentId.value,
         quoteEventMatchId |-> quoteEventMatchId.value,
         quoteEventExecId  |-> quoteEventExecId.value,
         quoteEventType    |-> quoteEventType.value,
         quoteEventSide    |-> quoteEventSide.value,
         pad2v2            |-> pad2v2.value ], pad2v2.rest)

ZeroBestQuoteExecutionReport ==
    [ pad2              |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp   |-> ZeroRbcHeaderMeComp,
      execId            |-> [i \in 1 .. 8 |-> 0],
      quoteMsgId        |-> [i \in 1 .. 8 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      quoteEventPx      |-> [i \in 1 .. 8 |-> 0],
      quoteEventQty     |-> [i \in 1 .. 8 |-> 0],
      reservedSize      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      quoteEventMatchId |-> [i \in 1 .. 4 |-> 0],
      quoteEventExecId  |-> [i \in 1 .. 4 |-> 0],
      quoteEventType    |-> [i \in 1 .. 1 |-> 0],
      quoteEventSide    |-> [i \in 1 .. 1 |-> 0],
      pad2v2            |-> [i \in 1 .. 2 |-> 0] ]

(* Best Quote Execution Report at zero, then each field in turn at the values it is checked at *)
CheckedBestQuoteExecutionReport ==
    { ZeroBestQuoteExecutionReport }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteMsgId = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventPx = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventQty = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.reservedSize = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventMatchId = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventType = one] : one \in Sample(1) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventSide = one] : one \in Sample(1) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Best Quote Response: 98 bytes                                           *)
(***************************************************************************)

BestQuoteResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp,
      quoteId                : Sample(8),
      quoteResponseId        : Sample(8),
      securityId             : Sample(8),
      bidCxlSize             : Sample(8),
      offerCxlSize           : Sample(8),
      marketSegmentId        : Sample(4),
      pad4                   : Sample(4) ]

EncodeBestQuoteResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp(message.nrResponseHeaderMeComp)
        \o message.quoteId
        \o message.quoteResponseId
        \o message.securityId
        \o message.bidCxlSize
        \o message.offerCxlSize
        \o message.marketSegmentId
        \o message.pad4

DecodeBestQuoteResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteResponseId == ReadBytes(quoteId.rest, 8) IN IF ~quoteResponseId.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteResponseId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidCxlSize == ReadBytes(securityId.rest, 8) IN IF ~bidCxlSize.ok THEN Fail ELSE
    LET offerCxlSize == ReadBytes(bidCxlSize.rest, 8) IN IF ~offerCxlSize.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(offerCxlSize.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(marketSegmentId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         quoteId                |-> quoteId.value,
         quoteResponseId        |-> quoteResponseId.value,
         securityId             |-> securityId.value,
         bidCxlSize             |-> bidCxlSize.value,
         offerCxlSize           |-> offerCxlSize.value,
         marketSegmentId        |-> marketSegmentId.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroBestQuoteResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp,
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      quoteResponseId        |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      bidCxlSize             |-> [i \in 1 .. 8 |-> 0],
      offerCxlSize           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Best Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedBestQuoteResponse ==
    { ZeroBestQuoteResponse }
        \cup { [ZeroBestQuoteResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp }
        \cup { [ZeroBestQuoteResponse EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.quoteResponseId = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.bidCxlSize = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.offerCxlSize = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.pad4 = one] : one \in Sample(4) }

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
    [ pad2             : Sample(2),
      notifHeaderComp  : NotifHeaderComp,
      applIdStatus     : Sample(4),
      refApplSubId     : Sample(4),
      refApplId        : Sample(1),
      sessionStatus    : Sample(1),
      pad4             : Sample(4),
      varText          : SampleBytes,
      alignmentPadding : SampleBytes ]

EncodeBroadcastErrorNotification(message) ==
    message.pad2
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
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp(pad2.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET applIdStatus == ReadBytes(notifHeaderComp.rest, 4) IN IF ~applIdStatus.ok THEN Fail ELSE
    LET refApplSubId == ReadBytes(applIdStatus.rest, 4) IN IF ~refApplSubId.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(refApplSubId.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET refApplId == ReadBytes(varTextLen.rest, 1) IN IF ~refApplId.ok THEN Fail ELSE
    LET sessionStatus == ReadBytes(refApplId.rest, 1) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET pad4 == ReadBytes(sessionStatus.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET varText == ReadBytes(pad4.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2             |-> pad2.value,
         notifHeaderComp  |-> notifHeaderComp.value,
         applIdStatus     |-> applIdStatus.value,
         refApplSubId     |-> refApplSubId.value,
         refApplId        |-> refApplId.value,
         sessionStatus    |-> sessionStatus.value,
         pad4             |-> pad4.value,
         varText          |-> varText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroBroadcastErrorNotification ==
    [ pad2             |-> [i \in 1 .. 2 |-> 0],
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
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.applIdStatus = one] : one \in Sample(4) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.refApplSubId = one] : one \in Sample(4) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.sessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroBroadcastErrorNotification EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp2 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp2(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp2(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp2 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp2 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Cross Request Response: 58 bytes                                        *)
(***************************************************************************)

CrossRequestResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp2,
      execId                 : Sample(8) ]

EncodeCrossRequestResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp2(message.nrResponseHeaderMeComp)
        \o message.execId

DecodeCrossRequestResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp2(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET execId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         execId                 |-> execId.value ], execId.rest)

ZeroCrossRequestResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp2,
      execId                 |-> [i \in 1 .. 8 |-> 0] ]

(* Cross Request Response at zero, then each field in turn at the values it is checked at *)
CheckedCrossRequestResponse ==
    { ZeroCrossRequestResponse }
        \cup { [ZeroCrossRequestResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroCrossRequestResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp2 }
        \cup { [ZeroCrossRequestResponse EXCEPT !.execId = one] : one \in Sample(8) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp2 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp2 EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Affected Ord Grp Comp: 16 bytes                                         *)
(***************************************************************************)

AffectedOrdGrpComp ==
    [ affectedOrderId     : Sample(8),
      affectedOrigClOrdId : Sample(8) ]

EncodeAffectedOrdGrpComp(message) ==
    message.affectedOrderId
        \o message.affectedOrigClOrdId

DecodeAffectedOrdGrpComp(bytes) ==
    LET affectedOrderId == ReadBytes(bytes, 8) IN IF ~affectedOrderId.ok THEN Fail ELSE
    LET affectedOrigClOrdId == ReadBytes(affectedOrderId.rest, 8) IN IF ~affectedOrigClOrdId.ok THEN Fail ELSE
    Ok([ affectedOrderId     |-> affectedOrderId.value,
         affectedOrigClOrdId |-> affectedOrigClOrdId.value ], affectedOrigClOrdId.rest)

ZeroAffectedOrdGrpComp ==
    [ affectedOrderId     |-> [i \in 1 .. 8 |-> 0],
      affectedOrigClOrdId |-> [i \in 1 .. 8 |-> 0] ]

(* Affected Ord Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedAffectedOrdGrpComp ==
    { ZeroAffectedOrdGrpComp }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.affectedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroAffectedOrdGrpComp EXCEPT !.affectedOrigClOrdId = one] : one \in Sample(8) }

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
(* Affected Order Requests Grp Comp: 8 bytes                               *)
(***************************************************************************)

AffectedOrderRequestsGrpComp ==
    [ affectedOrderRequestId : Sample(4),
      pad4                   : Sample(4) ]

EncodeAffectedOrderRequestsGrpComp(message) ==
    message.affectedOrderRequestId
        \o message.pad4

DecodeAffectedOrderRequestsGrpComp(bytes) ==
    LET affectedOrderRequestId == ReadBytes(bytes, 4) IN IF ~affectedOrderRequestId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(affectedOrderRequestId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ affectedOrderRequestId |-> affectedOrderRequestId.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroAffectedOrderRequestsGrpComp ==
    [ affectedOrderRequestId |-> [i \in 1 .. 4 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Affected Order Requests Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedAffectedOrderRequestsGrpComp ==
    { ZeroAffectedOrderRequestsGrpComp }
        \cup { [ZeroAffectedOrderRequestsGrpComp EXCEPT !.affectedOrderRequestId = one] : one \in Sample(4) }
        \cup { [ZeroAffectedOrderRequestsGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Affected Order Requests Grp Comp, written one after another *)
RECURSIVE EncodeAffectedOrderRequestsGrpCompList(_)
EncodeAffectedOrderRequestsGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAffectedOrderRequestsGrpComp(Head(messages)) \o EncodeAffectedOrderRequestsGrpCompList(Tail(messages))

(* As many Affected Order Requests Grp Comp as the field that counts them says *)
RECURSIVE ReadAffectedOrderRequestsGrpCompList(_, _)
ReadAffectedOrderRequestsGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAffectedOrderRequestsGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAffectedOrderRequestsGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Affected Order Requests Grp Comp of each kind, for the lists that carry them *)
OneAffectedOrderRequestsGrpComp == { ZeroAffectedOrderRequestsGrpComp }

(***************************************************************************)
(* Delete All Order Broadcast                                              *)
(***************************************************************************)

DeleteAllOrderBroadcast ==
    [ pad2                         : Sample(2),
      rbcHeaderMeComp              : RbcHeaderMeComp2,
      massActionReportId           : Sample(8),
      securityId                   : Sample(8),
      price                        : Sample(8),
      marketSegmentId              : Sample(4),
      targetPartyIdSessionId       : Sample(4),
      targetPartyIdExecutingTrader : Sample(4),
      partyIdEnteringTrader        : Sample(4),
      partyIdEnteringFirm          : Sample(1),
      massActionReason             : Sample(1),
      execInst                     : Sample(1),
      side                         : Sample(1),
      pad6                         : Sample(6),
      notAffectedOrdersGrpComp     : SampleLists(OneNotAffectedOrdersGrpComp),
      affectedOrdGrpComp           : SampleLists(OneAffectedOrdGrpComp),
      affectedOrderRequestsGrpComp : SampleLists(OneAffectedOrderRequestsGrpComp) ]

EncodeDeleteAllOrderBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp2(message.rbcHeaderMeComp)
        \o message.massActionReportId
        \o message.securityId
        \o message.price
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.targetPartyIdExecutingTrader
        \o message.partyIdEnteringTrader
        \o EncodeUIntLE(Len(message.notAffectedOrdersGrpComp), 2)
        \o EncodeUIntLE(Len(message.affectedOrdGrpComp), 2)
        \o EncodeUIntLE(Len(message.affectedOrderRequestsGrpComp), 2)
        \o message.partyIdEnteringFirm
        \o message.massActionReason
        \o message.execInst
        \o message.side
        \o message.pad6
        \o EncodeNotAffectedOrdersGrpCompList(message.notAffectedOrdersGrpComp)
        \o EncodeAffectedOrdGrpCompList(message.affectedOrdGrpComp)
        \o EncodeAffectedOrderRequestsGrpCompList(message.affectedOrderRequestsGrpComp)

DecodeDeleteAllOrderBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp2(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET securityId == ReadBytes(massActionReportId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(price.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET targetPartyIdExecutingTrader == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(targetPartyIdExecutingTrader.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET noNotAffectedOrders == ReadUIntLE(partyIdEnteringTrader.rest, 2) IN IF ~noNotAffectedOrders.ok THEN Fail ELSE
    LET noAffectedOrders == ReadUIntLE(noNotAffectedOrders.rest, 2) IN IF ~noAffectedOrders.ok THEN Fail ELSE
    LET noAffectedOrderRequests == ReadUIntLE(noAffectedOrders.rest, 2) IN IF ~noAffectedOrderRequests.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(noAffectedOrderRequests.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET massActionReason == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~massActionReason.ok THEN Fail ELSE
    LET execInst == ReadBytes(massActionReason.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET side == ReadBytes(execInst.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad6 == ReadBytes(side.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET notAffectedOrdersGrpComp == ReadNotAffectedOrdersGrpCompList(pad6.rest, noNotAffectedOrders.value) IN IF ~notAffectedOrdersGrpComp.ok THEN Fail ELSE
    LET affectedOrdGrpComp == ReadAffectedOrdGrpCompList(notAffectedOrdersGrpComp.rest, noAffectedOrders.value) IN IF ~affectedOrdGrpComp.ok THEN Fail ELSE
    LET affectedOrderRequestsGrpComp == ReadAffectedOrderRequestsGrpCompList(affectedOrdGrpComp.rest, noAffectedOrderRequests.value) IN IF ~affectedOrderRequestsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                         |-> pad2.value,
         rbcHeaderMeComp              |-> rbcHeaderMeComp.value,
         massActionReportId           |-> massActionReportId.value,
         securityId                   |-> securityId.value,
         price                        |-> price.value,
         marketSegmentId              |-> marketSegmentId.value,
         targetPartyIdSessionId       |-> targetPartyIdSessionId.value,
         targetPartyIdExecutingTrader |-> targetPartyIdExecutingTrader.value,
         partyIdEnteringTrader        |-> partyIdEnteringTrader.value,
         partyIdEnteringFirm          |-> partyIdEnteringFirm.value,
         massActionReason             |-> massActionReason.value,
         execInst                     |-> execInst.value,
         side                         |-> side.value,
         pad6                         |-> pad6.value,
         notAffectedOrdersGrpComp     |-> notAffectedOrdersGrpComp.value,
         affectedOrdGrpComp           |-> affectedOrdGrpComp.value,
         affectedOrderRequestsGrpComp |-> affectedOrderRequestsGrpComp.value ], affectedOrderRequestsGrpComp.rest)

ZeroDeleteAllOrderBroadcast ==
    [ pad2                         |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp              |-> ZeroRbcHeaderMeComp2,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId              |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId       |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader        |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringFirm          |-> [i \in 1 .. 1 |-> 0],
      massActionReason             |-> [i \in 1 .. 1 |-> 0],
      execInst                     |-> [i \in 1 .. 1 |-> 0],
      side                         |-> [i \in 1 .. 1 |-> 0],
      pad6                         |-> [i \in 1 .. 6 |-> 0],
      notAffectedOrdersGrpComp     |-> << >>,
      affectedOrdGrpComp           |-> << >>,
      affectedOrderRequestsGrpComp |-> << >> ]

(* Delete All Order Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderBroadcast ==
    { ZeroDeleteAllOrderBroadcast }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp2 }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.massActionReason = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.notAffectedOrdersGrpComp = one] : one \in SampleLists(OneNotAffectedOrdersGrpComp) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.affectedOrdGrpComp = one] : one \in SampleLists(OneAffectedOrdGrpComp) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.affectedOrderRequestsGrpComp = one] : one \in SampleLists(OneAffectedOrderRequestsGrpComp) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp3 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp3(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp3(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp3 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp3 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Delete All Order Nr Response: 58 bytes                                  *)
(***************************************************************************)

DeleteAllOrderNrResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp3,
      massActionReportId     : Sample(8) ]

EncodeDeleteAllOrderNrResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp3(message.nrResponseHeaderMeComp)
        \o message.massActionReportId

DecodeDeleteAllOrderNrResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp3(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         massActionReportId     |-> massActionReportId.value ], massActionReportId.rest)

ZeroDeleteAllOrderNrResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp3,
      massActionReportId     |-> [i \in 1 .. 8 |-> 0] ]

(* Delete All Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderNrResponse ==
    { ZeroDeleteAllOrderNrResponse }
        \cup { [ZeroDeleteAllOrderNrResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp3 }
        \cup { [ZeroDeleteAllOrderNrResponse EXCEPT !.massActionReportId = one] : one \in Sample(8) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp3 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp3 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Delete All Order Quote Event Broadcast: 82 bytes                        *)
(***************************************************************************)

DeleteAllOrderQuoteEventBroadcast ==
    [ pad2               : Sample(2),
      rbcHeaderMeComp    : RbcHeaderMeComp3,
      massActionReportId : Sample(8),
      securityId         : Sample(8),
      marketSegmentId    : Sample(4),
      massActionReason   : Sample(1),
      execInst           : Sample(1),
      pad2v2             : Sample(2) ]

EncodeDeleteAllOrderQuoteEventBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp3(message.rbcHeaderMeComp)
        \o message.massActionReportId
        \o message.securityId
        \o message.marketSegmentId
        \o message.massActionReason
        \o message.execInst
        \o message.pad2v2

DecodeDeleteAllOrderQuoteEventBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp3(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET securityId == ReadBytes(massActionReportId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(securityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET massActionReason == ReadBytes(marketSegmentId.rest, 1) IN IF ~massActionReason.ok THEN Fail ELSE
    LET execInst == ReadBytes(massActionReason.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(execInst.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         rbcHeaderMeComp    |-> rbcHeaderMeComp.value,
         massActionReportId |-> massActionReportId.value,
         securityId         |-> securityId.value,
         marketSegmentId    |-> marketSegmentId.value,
         massActionReason   |-> massActionReason.value,
         execInst           |-> execInst.value,
         pad2v2             |-> pad2v2.value ], pad2v2.rest)

ZeroDeleteAllOrderQuoteEventBroadcast ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp    |-> ZeroRbcHeaderMeComp3,
      massActionReportId |-> [i \in 1 .. 8 |-> 0],
      securityId         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      massActionReason   |-> [i \in 1 .. 1 |-> 0],
      execInst           |-> [i \in 1 .. 1 |-> 0],
      pad2v2             |-> [i \in 1 .. 2 |-> 0] ]

(* Delete All Order Quote Event Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderQuoteEventBroadcast ==
    { ZeroDeleteAllOrderQuoteEventBroadcast }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp3 }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.massActionReason = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderQuoteEventBroadcast EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Response Header Me Comp: 64 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp ==
    [ requestTime     : Sample(8),
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
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
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
(* Affected Ord Grp Comp: 16 bytes                                         *)
(***************************************************************************)

AffectedOrdGrpComp2 ==
    [ affectedOrderId     : Sample(8),
      affectedOrigClOrdId : Sample(8) ]

EncodeAffectedOrdGrpComp2(message) ==
    message.affectedOrderId
        \o message.affectedOrigClOrdId

DecodeAffectedOrdGrpComp2(bytes) ==
    LET affectedOrderId == ReadBytes(bytes, 8) IN IF ~affectedOrderId.ok THEN Fail ELSE
    LET affectedOrigClOrdId == ReadBytes(affectedOrderId.rest, 8) IN IF ~affectedOrigClOrdId.ok THEN Fail ELSE
    Ok([ affectedOrderId     |-> affectedOrderId.value,
         affectedOrigClOrdId |-> affectedOrigClOrdId.value ], affectedOrigClOrdId.rest)

ZeroAffectedOrdGrpComp2 ==
    [ affectedOrderId     |-> [i \in 1 .. 8 |-> 0],
      affectedOrigClOrdId |-> [i \in 1 .. 8 |-> 0] ]

(* Affected Ord Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedAffectedOrdGrpComp2 ==
    { ZeroAffectedOrdGrpComp2 }
        \cup { [ZeroAffectedOrdGrpComp2 EXCEPT !.affectedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroAffectedOrdGrpComp2 EXCEPT !.affectedOrigClOrdId = one] : one \in Sample(8) }

(* A run of Affected Ord Grp Comp, written one after another *)
RECURSIVE EncodeAffectedOrdGrpComp2List(_)
EncodeAffectedOrdGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAffectedOrdGrpComp2(Head(messages)) \o EncodeAffectedOrdGrpComp2List(Tail(messages))

(* As many Affected Ord Grp Comp as the field that counts them says *)
RECURSIVE ReadAffectedOrdGrpComp2List(_, _)
ReadAffectedOrdGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAffectedOrdGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAffectedOrdGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Affected Ord Grp Comp of each kind, for the lists that carry them *)
OneAffectedOrdGrpComp2 == { ZeroAffectedOrdGrpComp2 }

(***************************************************************************)
(* Affected Order Requests Grp Comp: 8 bytes                               *)
(***************************************************************************)

AffectedOrderRequestsGrpComp2 ==
    [ affectedOrderRequestId : Sample(4),
      pad4                   : Sample(4) ]

EncodeAffectedOrderRequestsGrpComp2(message) ==
    message.affectedOrderRequestId
        \o message.pad4

DecodeAffectedOrderRequestsGrpComp2(bytes) ==
    LET affectedOrderRequestId == ReadBytes(bytes, 4) IN IF ~affectedOrderRequestId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(affectedOrderRequestId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ affectedOrderRequestId |-> affectedOrderRequestId.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroAffectedOrderRequestsGrpComp2 ==
    [ affectedOrderRequestId |-> [i \in 1 .. 4 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Affected Order Requests Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedAffectedOrderRequestsGrpComp2 ==
    { ZeroAffectedOrderRequestsGrpComp2 }
        \cup { [ZeroAffectedOrderRequestsGrpComp2 EXCEPT !.affectedOrderRequestId = one] : one \in Sample(4) }
        \cup { [ZeroAffectedOrderRequestsGrpComp2 EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Affected Order Requests Grp Comp, written one after another *)
RECURSIVE EncodeAffectedOrderRequestsGrpComp2List(_)
EncodeAffectedOrderRequestsGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAffectedOrderRequestsGrpComp2(Head(messages)) \o EncodeAffectedOrderRequestsGrpComp2List(Tail(messages))

(* As many Affected Order Requests Grp Comp as the field that counts them says *)
RECURSIVE ReadAffectedOrderRequestsGrpComp2List(_, _)
ReadAffectedOrderRequestsGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAffectedOrderRequestsGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAffectedOrderRequestsGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Affected Order Requests Grp Comp of each kind, for the lists that carry them *)
OneAffectedOrderRequestsGrpComp2 == { ZeroAffectedOrderRequestsGrpComp2 }

(***************************************************************************)
(* Delete All Order Response                                               *)
(***************************************************************************)

DeleteAllOrderResponse ==
    [ pad2                         : Sample(2),
      responseHeaderMeComp         : ResponseHeaderMeComp,
      massActionReportId           : Sample(8),
      pad2v2                       : Sample(2),
      notAffectedOrdersGrpComp     : SampleLists(OneNotAffectedOrdersGrpComp2),
      affectedOrdGrpComp           : SampleLists(OneAffectedOrdGrpComp2),
      affectedOrderRequestsGrpComp : SampleLists(OneAffectedOrderRequestsGrpComp2) ]

EncodeDeleteAllOrderResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderMeComp(message.responseHeaderMeComp)
        \o message.massActionReportId
        \o EncodeUIntLE(Len(message.notAffectedOrdersGrpComp), 2)
        \o EncodeUIntLE(Len(message.affectedOrdGrpComp), 2)
        \o EncodeUIntLE(Len(message.affectedOrderRequestsGrpComp), 2)
        \o message.pad2v2
        \o EncodeNotAffectedOrdersGrpComp2List(message.notAffectedOrdersGrpComp)
        \o EncodeAffectedOrdGrpComp2List(message.affectedOrdGrpComp)
        \o EncodeAffectedOrderRequestsGrpComp2List(message.affectedOrderRequestsGrpComp)

DecodeDeleteAllOrderResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp(pad2.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET noNotAffectedOrders == ReadUIntLE(massActionReportId.rest, 2) IN IF ~noNotAffectedOrders.ok THEN Fail ELSE
    LET noAffectedOrders == ReadUIntLE(noNotAffectedOrders.rest, 2) IN IF ~noAffectedOrders.ok THEN Fail ELSE
    LET noAffectedOrderRequests == ReadUIntLE(noAffectedOrders.rest, 2) IN IF ~noAffectedOrderRequests.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(noAffectedOrderRequests.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET notAffectedOrdersGrpComp == ReadNotAffectedOrdersGrpComp2List(pad2v2.rest, noNotAffectedOrders.value) IN IF ~notAffectedOrdersGrpComp.ok THEN Fail ELSE
    LET affectedOrdGrpComp == ReadAffectedOrdGrpComp2List(notAffectedOrdersGrpComp.rest, noAffectedOrders.value) IN IF ~affectedOrdGrpComp.ok THEN Fail ELSE
    LET affectedOrderRequestsGrpComp == ReadAffectedOrderRequestsGrpComp2List(affectedOrdGrpComp.rest, noAffectedOrderRequests.value) IN IF ~affectedOrderRequestsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                         |-> pad2.value,
         responseHeaderMeComp         |-> responseHeaderMeComp.value,
         massActionReportId           |-> massActionReportId.value,
         pad2v2                       |-> pad2v2.value,
         notAffectedOrdersGrpComp     |-> notAffectedOrdersGrpComp.value,
         affectedOrdGrpComp           |-> affectedOrdGrpComp.value,
         affectedOrderRequestsGrpComp |-> affectedOrderRequestsGrpComp.value ], affectedOrderRequestsGrpComp.rest)

ZeroDeleteAllOrderResponse ==
    [ pad2                         |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp         |-> ZeroResponseHeaderMeComp,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      pad2v2                       |-> [i \in 1 .. 2 |-> 0],
      notAffectedOrdersGrpComp     |-> << >>,
      affectedOrdGrpComp           |-> << >>,
      affectedOrderRequestsGrpComp |-> << >> ]

(* Delete All Order Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderResponse ==
    { ZeroDeleteAllOrderResponse }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.notAffectedOrdersGrpComp = one] : one \in SampleLists(OneNotAffectedOrdersGrpComp2) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.affectedOrdGrpComp = one] : one \in SampleLists(OneAffectedOrdGrpComp2) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.affectedOrderRequestsGrpComp = one] : one \in SampleLists(OneAffectedOrderRequestsGrpComp2) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp4 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp4 EXCEPT !.pad7 = one] : one \in Sample(7) }

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
    [ pad2                         : Sample(2),
      rbcHeaderMeComp              : RbcHeaderMeComp4,
      massActionReportId           : Sample(8),
      securityId                   : Sample(8),
      marketSegmentId              : Sample(4),
      targetPartyIdSessionId       : Sample(4),
      partyIdEnteringTrader        : Sample(4),
      targetPartyIdExecutingTrader : Sample(4),
      massActionReason             : Sample(1),
      partyIdEnteringFirm          : Sample(1),
      targetPartyIdDeskId          : Sample(3),
      pad1                         : Sample(1),
      notAffectedSecuritiesGrpComp : SampleLists(OneNotAffectedSecuritiesGrpComp) ]

EncodeDeleteAllQuoteBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp4(message.rbcHeaderMeComp)
        \o message.massActionReportId
        \o message.securityId
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.partyIdEnteringTrader
        \o message.targetPartyIdExecutingTrader
        \o EncodeUIntLE(Len(message.notAffectedSecuritiesGrpComp), 2)
        \o message.massActionReason
        \o message.partyIdEnteringFirm
        \o message.targetPartyIdDeskId
        \o message.pad1
        \o EncodeNotAffectedSecuritiesGrpCompList(message.notAffectedSecuritiesGrpComp)

DecodeDeleteAllQuoteBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp4(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET securityId == ReadBytes(massActionReportId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(securityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET targetPartyIdExecutingTrader == ReadBytes(partyIdEnteringTrader.rest, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET noNotAffectedSecurities == ReadUIntLE(targetPartyIdExecutingTrader.rest, 2) IN IF ~noNotAffectedSecurities.ok THEN Fail ELSE
    LET massActionReason == ReadBytes(noNotAffectedSecurities.rest, 1) IN IF ~massActionReason.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(massActionReason.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET targetPartyIdDeskId == ReadBytes(partyIdEnteringFirm.rest, 3) IN IF ~targetPartyIdDeskId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(targetPartyIdDeskId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET notAffectedSecuritiesGrpComp == ReadNotAffectedSecuritiesGrpCompList(pad1.rest, noNotAffectedSecurities.value) IN IF ~notAffectedSecuritiesGrpComp.ok THEN Fail ELSE
    Ok([ pad2                         |-> pad2.value,
         rbcHeaderMeComp              |-> rbcHeaderMeComp.value,
         massActionReportId           |-> massActionReportId.value,
         securityId                   |-> securityId.value,
         marketSegmentId              |-> marketSegmentId.value,
         targetPartyIdSessionId       |-> targetPartyIdSessionId.value,
         partyIdEnteringTrader        |-> partyIdEnteringTrader.value,
         targetPartyIdExecutingTrader |-> targetPartyIdExecutingTrader.value,
         massActionReason             |-> massActionReason.value,
         partyIdEnteringFirm          |-> partyIdEnteringFirm.value,
         targetPartyIdDeskId          |-> targetPartyIdDeskId.value,
         pad1                         |-> pad1.value,
         notAffectedSecuritiesGrpComp |-> notAffectedSecuritiesGrpComp.value ], notAffectedSecuritiesGrpComp.rest)

ZeroDeleteAllQuoteBroadcast ==
    [ pad2                         |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp              |-> ZeroRbcHeaderMeComp4,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId              |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId       |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      massActionReason             |-> [i \in 1 .. 1 |-> 0],
      partyIdEnteringFirm          |-> [i \in 1 .. 1 |-> 0],
      targetPartyIdDeskId          |-> [i \in 1 .. 3 |-> 0],
      pad1                         |-> [i \in 1 .. 1 |-> 0],
      notAffectedSecuritiesGrpComp |-> << >> ]

(* Delete All Quote Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllQuoteBroadcast ==
    { ZeroDeleteAllQuoteBroadcast }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp4 }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.massActionReason = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.targetPartyIdDeskId = one] : one \in Sample(3) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteBroadcast EXCEPT !.notAffectedSecuritiesGrpComp = one] : one \in SampleLists(OneNotAffectedSecuritiesGrpComp) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp4 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp4(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp4(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp4 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp4 EXCEPT !.pad3 = one] : one \in Sample(3) }

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
    [ pad2                         : Sample(2),
      nrResponseHeaderMeComp       : NrResponseHeaderMeComp4,
      massActionReportId           : Sample(8),
      pad6                         : Sample(6),
      notAffectedSecuritiesGrpComp : SampleLists(OneNotAffectedSecuritiesGrpComp2) ]

EncodeDeleteAllQuoteResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp4(message.nrResponseHeaderMeComp)
        \o message.massActionReportId
        \o EncodeUIntLE(Len(message.notAffectedSecuritiesGrpComp), 2)
        \o message.pad6
        \o EncodeNotAffectedSecuritiesGrpComp2List(message.notAffectedSecuritiesGrpComp)

DecodeDeleteAllQuoteResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp4(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET noNotAffectedSecurities == ReadUIntLE(massActionReportId.rest, 2) IN IF ~noNotAffectedSecurities.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noNotAffectedSecurities.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET notAffectedSecuritiesGrpComp == ReadNotAffectedSecuritiesGrpComp2List(pad6.rest, noNotAffectedSecurities.value) IN IF ~notAffectedSecuritiesGrpComp.ok THEN Fail ELSE
    Ok([ pad2                         |-> pad2.value,
         nrResponseHeaderMeComp       |-> nrResponseHeaderMeComp.value,
         massActionReportId           |-> massActionReportId.value,
         pad6                         |-> pad6.value,
         notAffectedSecuritiesGrpComp |-> notAffectedSecuritiesGrpComp.value ], notAffectedSecuritiesGrpComp.rest)

ZeroDeleteAllQuoteResponse ==
    [ pad2                         |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp       |-> ZeroNrResponseHeaderMeComp4,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      pad6                         |-> [i \in 1 .. 6 |-> 0],
      notAffectedSecuritiesGrpComp |-> << >> ]

(* Delete All Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllQuoteResponse ==
    { ZeroDeleteAllQuoteResponse }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp4 }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroDeleteAllQuoteResponse EXCEPT !.notAffectedSecuritiesGrpComp = one] : one \in SampleLists(OneNotAffectedSecuritiesGrpComp2) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp5 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp5 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Delete Order Broadcast: 178 bytes                                       *)
(***************************************************************************)

DeleteOrderBroadcast ==
    [ pad2                  : Sample(2),
      rbcHeaderMeComp       : RbcHeaderMeComp5,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      cumQty                : Sample(8),
      cxlQty                : Sample(8),
      quoteId               : Sample(8),
      orderIdSfx            : Sample(4),
      marketSegmentId       : Sample(4),
      partyIdEnteringTrader : Sample(4),
      partyIdSessionId      : Sample(4),
      execRestatementReason : Sample(2),
      partyIdEnteringFirm   : Sample(1),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      side                  : Sample(1),
      orderEventType        : Sample(1),
      fixClOrdId            : Sample(20),
      partyEnteringFirm     : Sample(5),
      partyEnteringTrader   : Sample(6),
      pad2v2                : Sample(2) ]

EncodeDeleteOrderBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp5(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.cumQty
        \o message.cxlQty
        \o message.quoteId
        \o message.orderIdSfx
        \o message.marketSegmentId
        \o message.partyIdEnteringTrader
        \o message.partyIdSessionId
        \o message.execRestatementReason
        \o message.partyIdEnteringFirm
        \o message.ordStatus
        \o message.execType
        \o message.side
        \o message.orderEventType
        \o message.fixClOrdId
        \o message.partyEnteringFirm
        \o message.partyEnteringTrader
        \o message.pad2v2

DecodeDeleteOrderBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp5(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(execId.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET quoteId == ReadBytes(cxlQty.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(quoteId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderIdSfx.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(marketSegmentId.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(partyIdEnteringTrader.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(partyIdSessionId.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(execRestatementReason.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET side == ReadBytes(execType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderEventType == ReadBytes(side.rest, 1) IN IF ~orderEventType.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(orderEventType.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET partyEnteringFirm == ReadBytes(fixClOrdId.rest, 5) IN IF ~partyEnteringFirm.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyEnteringFirm.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(partyEnteringTrader.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         rbcHeaderMeComp       |-> rbcHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         quoteId               |-> quoteId.value,
         orderIdSfx            |-> orderIdSfx.value,
         marketSegmentId       |-> marketSegmentId.value,
         partyIdEnteringTrader |-> partyIdEnteringTrader.value,
         partyIdSessionId      |-> partyIdSessionId.value,
         execRestatementReason |-> execRestatementReason.value,
         partyIdEnteringFirm   |-> partyIdEnteringFirm.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         side                  |-> side.value,
         orderEventType        |-> orderEventType.value,
         fixClOrdId            |-> fixClOrdId.value,
         partyEnteringFirm     |-> partyEnteringFirm.value,
         partyEnteringTrader   |-> partyEnteringTrader.value,
         pad2v2                |-> pad2v2.value ], pad2v2.rest)

ZeroDeleteOrderBroadcast ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp       |-> ZeroRbcHeaderMeComp5,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      cumQty                |-> [i \in 1 .. 8 |-> 0],
      cxlQty                |-> [i \in 1 .. 8 |-> 0],
      quoteId               |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId      |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      partyIdEnteringFirm   |-> [i \in 1 .. 1 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      orderEventType        |-> [i \in 1 .. 1 |-> 0],
      fixClOrdId            |-> [i \in 1 .. 20 |-> 0],
      partyEnteringFirm     |-> [i \in 1 .. 5 |-> 0],
      partyEnteringTrader   |-> [i \in 1 .. 6 |-> 0],
      pad2v2                |-> [i \in 1 .. 2 |-> 0] ]

(* Delete Order Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderBroadcast ==
    { ZeroDeleteOrderBroadcast }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp5 }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.orderEventType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyEnteringFirm = one] : one \in Sample(5) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp5 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp5(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp5(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp5 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp5 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Delete Order Nr Response: 122 bytes                                     *)
(***************************************************************************)

DeleteOrderNrResponse ==
    [ pad2                      : Sample(2),
      nrResponseHeaderMeComp    : NrResponseHeaderMeComp5,
      orderId                   : Sample(8),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      securityId                : Sample(8),
      execId                    : Sample(8),
      cumQty                    : Sample(8),
      cxlQty                    : Sample(8),
      orderIdSfx                : Sample(4),
      ordStatus                 : Sample(1),
      execType                  : Sample(1),
      execRestatementReason     : Sample(2),
      transactionDelayIndicator : Sample(1),
      pad7                      : Sample(7) ]

EncodeDeleteOrderNrResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp5(message.nrResponseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.cumQty
        \o message.cxlQty
        \o message.orderIdSfx
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.transactionDelayIndicator
        \o message.pad7

DecodeDeleteOrderNrResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp5(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(execId.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(cxlQty.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderIdSfx.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET transactionDelayIndicator == ReadBytes(execRestatementReason.rest, 1) IN IF ~transactionDelayIndicator.ok THEN Fail ELSE
    LET pad7 == ReadBytes(transactionDelayIndicator.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2                      |-> pad2.value,
         nrResponseHeaderMeComp    |-> nrResponseHeaderMeComp.value,
         orderId                   |-> orderId.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         securityId                |-> securityId.value,
         execId                    |-> execId.value,
         cumQty                    |-> cumQty.value,
         cxlQty                    |-> cxlQty.value,
         orderIdSfx                |-> orderIdSfx.value,
         ordStatus                 |-> ordStatus.value,
         execType                  |-> execType.value,
         execRestatementReason     |-> execRestatementReason.value,
         transactionDelayIndicator |-> transactionDelayIndicator.value,
         pad7                      |-> pad7.value ], pad7.rest)

ZeroDeleteOrderNrResponse ==
    [ pad2                      |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp    |-> ZeroNrResponseHeaderMeComp5,
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      cumQty                    |-> [i \in 1 .. 8 |-> 0],
      cxlQty                    |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx                |-> [i \in 1 .. 4 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 2 |-> 0],
      transactionDelayIndicator |-> [i \in 1 .. 1 |-> 0],
      pad7                      |-> [i \in 1 .. 7 |-> 0] ]

(* Delete Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderNrResponse ==
    { ZeroDeleteOrderNrResponse }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp5 }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.transactionDelayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Response Header Me Comp: 64 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp2 ==
    [ requestTime     : Sample(8),
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
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
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
(* Delete Order Response: 138 bytes                                        *)
(***************************************************************************)

DeleteOrderResponse ==
    [ pad2                      : Sample(2),
      responseHeaderMeComp      : ResponseHeaderMeComp2,
      orderId                   : Sample(8),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      securityId                : Sample(8),
      execId                    : Sample(8),
      cumQty                    : Sample(8),
      cxlQty                    : Sample(8),
      orderIdSfx                : Sample(4),
      ordStatus                 : Sample(1),
      execType                  : Sample(1),
      execRestatementReason     : Sample(2),
      transactionDelayIndicator : Sample(1),
      pad7                      : Sample(7) ]

EncodeDeleteOrderResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderMeComp2(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.cumQty
        \o message.cxlQty
        \o message.orderIdSfx
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.transactionDelayIndicator
        \o message.pad7

DecodeDeleteOrderResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp2(pad2.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(execId.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(cxlQty.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderIdSfx.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET transactionDelayIndicator == ReadBytes(execRestatementReason.rest, 1) IN IF ~transactionDelayIndicator.ok THEN Fail ELSE
    LET pad7 == ReadBytes(transactionDelayIndicator.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2                      |-> pad2.value,
         responseHeaderMeComp      |-> responseHeaderMeComp.value,
         orderId                   |-> orderId.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         securityId                |-> securityId.value,
         execId                    |-> execId.value,
         cumQty                    |-> cumQty.value,
         cxlQty                    |-> cxlQty.value,
         orderIdSfx                |-> orderIdSfx.value,
         ordStatus                 |-> ordStatus.value,
         execType                  |-> execType.value,
         execRestatementReason     |-> execRestatementReason.value,
         transactionDelayIndicator |-> transactionDelayIndicator.value,
         pad7                      |-> pad7.value ], pad7.rest)

ZeroDeleteOrderResponse ==
    [ pad2                      |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp      |-> ZeroResponseHeaderMeComp2,
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      cumQty                    |-> [i \in 1 .. 8 |-> 0],
      cxlQty                    |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx                |-> [i \in 1 .. 4 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 2 |-> 0],
      transactionDelayIndicator |-> [i \in 1 .. 1 |-> 0],
      pad7                      |-> [i \in 1 .. 7 |-> 0] ]

(* Delete Order Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderResponse ==
    { ZeroDeleteOrderResponse }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp2 }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.transactionDelayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp6 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp6 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Extended Deletion Report: 338 bytes                                     *)
(***************************************************************************)

ExtendedDeletionReport ==
    [ pad2                   : Sample(2),
      rbcHeaderMeComp        : RbcHeaderMeComp6,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      trdRegTsEntryTime      : Sample(8),
      price                  : Sample(8),
      leavesQty              : Sample(8),
      cumQty                 : Sample(8),
      cxlQty                 : Sample(8),
      orderQty               : Sample(8),
      displayQty             : Sample(8),
      displayLowQty          : Sample(8),
      displayHighQty         : Sample(8),
      stopPx                 : Sample(8),
      volumeDiscoveryPrice   : Sample(8),
      pegOffsetValueAbs      : Sample(8),
      pegOffsetValuePct      : Sample(8),
      quoteId                : Sample(8),
      marketSegmentId        : Sample(4),
      orderIdSfx             : Sample(4),
      expireDate             : Sample(4),
      matchInstCrossId       : Sample(4),
      partyIdExecutingUnit   : Sample(4),
      partyIdSessionId       : Sample(4),
      partyIdExecutingTrader : Sample(4),
      partyIdEnteringTrader  : Sample(4),
      execRestatementReason  : Sample(2),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      side                   : Sample(1),
      ordType                : Sample(1),
      tradingCapacity        : Sample(1),
      timeInForce            : Sample(1),
      execInst               : Sample(1),
      tradingSessionSubId    : Sample(1),
      applSeqIndicator       : Sample(1),
      exDestinationType      : Sample(1),
      freeText1              : Sample(12),
      freeText2              : Sample(12),
      freeText4              : Sample(16),
      partyEnteringFirm      : Sample(5),
      partyEnteringTrader    : Sample(6),
      partyExecutingFirm     : Sample(5),
      partyExecutingTrader   : Sample(6),
      fixClOrdId             : Sample(20),
      triggered              : Sample(1),
      pad1                   : Sample(1) ]

EncodeExtendedDeletionReport(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp6(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.trdRegTsEntryTime
        \o message.price
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.orderQty
        \o message.displayQty
        \o message.displayLowQty
        \o message.displayHighQty
        \o message.stopPx
        \o message.volumeDiscoveryPrice
        \o message.pegOffsetValueAbs
        \o message.pegOffsetValuePct
        \o message.quoteId
        \o message.marketSegmentId
        \o message.orderIdSfx
        \o message.expireDate
        \o message.matchInstCrossId
        \o message.partyIdExecutingUnit
        \o message.partyIdSessionId
        \o message.partyIdExecutingTrader
        \o message.partyIdEnteringTrader
        \o message.execRestatementReason
        \o message.ordStatus
        \o message.execType
        \o message.side
        \o message.ordType
        \o message.tradingCapacity
        \o message.timeInForce
        \o message.execInst
        \o message.tradingSessionSubId
        \o message.applSeqIndicator
        \o message.exDestinationType
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.partyEnteringFirm
        \o message.partyEnteringTrader
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.fixClOrdId
        \o message.triggered
        \o message.pad1

DecodeExtendedDeletionReport(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp6(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET trdRegTsEntryTime == ReadBytes(execId.rest, 8) IN IF ~trdRegTsEntryTime.ok THEN Fail ELSE
    LET price == ReadBytes(trdRegTsEntryTime.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(price.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(cxlQty.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(orderQty.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayLowQty == ReadBytes(displayQty.rest, 8) IN IF ~displayLowQty.ok THEN Fail ELSE
    LET displayHighQty == ReadBytes(displayLowQty.rest, 8) IN IF ~displayHighQty.ok THEN Fail ELSE
    LET stopPx == ReadBytes(displayHighQty.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET volumeDiscoveryPrice == ReadBytes(stopPx.rest, 8) IN IF ~volumeDiscoveryPrice.ok THEN Fail ELSE
    LET pegOffsetValueAbs == ReadBytes(volumeDiscoveryPrice.rest, 8) IN IF ~pegOffsetValueAbs.ok THEN Fail ELSE
    LET pegOffsetValuePct == ReadBytes(pegOffsetValueAbs.rest, 8) IN IF ~pegOffsetValuePct.ok THEN Fail ELSE
    LET quoteId == ReadBytes(pegOffsetValuePct.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET expireDate == ReadBytes(orderIdSfx.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(expireDate.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(matchInstCrossId.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(partyIdExecutingUnit.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET partyIdExecutingTrader == ReadBytes(partyIdSessionId.rest, 4) IN IF ~partyIdExecutingTrader.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(partyIdExecutingTrader.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(partyIdEnteringTrader.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execRestatementReason.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET side == ReadBytes(execType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(ordType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(tradingCapacity.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(execInst.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET exDestinationType == ReadBytes(applSeqIndicator.rest, 1) IN IF ~exDestinationType.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(exDestinationType.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET partyEnteringFirm == ReadBytes(freeText4.rest, 5) IN IF ~partyEnteringFirm.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyEnteringFirm.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(partyEnteringTrader.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(partyExecutingTrader.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET triggered == ReadBytes(fixClOrdId.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET pad1 == ReadBytes(triggered.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         rbcHeaderMeComp        |-> rbcHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         trdRegTsEntryTime      |-> trdRegTsEntryTime.value,
         price                  |-> price.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         orderQty               |-> orderQty.value,
         displayQty             |-> displayQty.value,
         displayLowQty          |-> displayLowQty.value,
         displayHighQty         |-> displayHighQty.value,
         stopPx                 |-> stopPx.value,
         volumeDiscoveryPrice   |-> volumeDiscoveryPrice.value,
         pegOffsetValueAbs      |-> pegOffsetValueAbs.value,
         pegOffsetValuePct      |-> pegOffsetValuePct.value,
         quoteId                |-> quoteId.value,
         marketSegmentId        |-> marketSegmentId.value,
         orderIdSfx             |-> orderIdSfx.value,
         expireDate             |-> expireDate.value,
         matchInstCrossId       |-> matchInstCrossId.value,
         partyIdExecutingUnit   |-> partyIdExecutingUnit.value,
         partyIdSessionId       |-> partyIdSessionId.value,
         partyIdExecutingTrader |-> partyIdExecutingTrader.value,
         partyIdEnteringTrader  |-> partyIdEnteringTrader.value,
         execRestatementReason  |-> execRestatementReason.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         side                   |-> side.value,
         ordType                |-> ordType.value,
         tradingCapacity        |-> tradingCapacity.value,
         timeInForce            |-> timeInForce.value,
         execInst               |-> execInst.value,
         tradingSessionSubId    |-> tradingSessionSubId.value,
         applSeqIndicator       |-> applSeqIndicator.value,
         exDestinationType      |-> exDestinationType.value,
         freeText1              |-> freeText1.value,
         freeText2              |-> freeText2.value,
         freeText4              |-> freeText4.value,
         partyEnteringFirm      |-> partyEnteringFirm.value,
         partyEnteringTrader    |-> partyEnteringTrader.value,
         partyExecutingFirm     |-> partyExecutingFirm.value,
         partyExecutingTrader   |-> partyExecutingTrader.value,
         fixClOrdId             |-> fixClOrdId.value,
         triggered              |-> triggered.value,
         pad1                   |-> pad1.value ], pad1.rest)

ZeroExtendedDeletionReport ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp        |-> ZeroRbcHeaderMeComp6,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime      |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 8 |-> 0],
      cumQty                 |-> [i \in 1 .. 8 |-> 0],
      cxlQty                 |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 8 |-> 0],
      displayQty             |-> [i \in 1 .. 8 |-> 0],
      displayLowQty          |-> [i \in 1 .. 8 |-> 0],
      displayHighQty         |-> [i \in 1 .. 8 |-> 0],
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      volumeDiscoveryPrice   |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValueAbs      |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValuePct      |-> [i \in 1 .. 8 |-> 0],
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx             |-> [i \in 1 .. 4 |-> 0],
      expireDate             |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId       |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingUnit   |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId       |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader  |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity        |-> [i \in 1 .. 1 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId    |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator       |-> [i \in 1 .. 1 |-> 0],
      exDestinationType      |-> [i \in 1 .. 1 |-> 0],
      freeText1              |-> [i \in 1 .. 12 |-> 0],
      freeText2              |-> [i \in 1 .. 12 |-> 0],
      freeText4              |-> [i \in 1 .. 16 |-> 0],
      partyEnteringFirm      |-> [i \in 1 .. 5 |-> 0],
      partyEnteringTrader    |-> [i \in 1 .. 6 |-> 0],
      partyExecutingFirm     |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader   |-> [i \in 1 .. 6 |-> 0],
      fixClOrdId             |-> [i \in 1 .. 20 |-> 0],
      triggered              |-> [i \in 1 .. 1 |-> 0],
      pad1                   |-> [i \in 1 .. 1 |-> 0] ]

(* Extended Deletion Report at zero, then each field in turn at the values it is checked at *)
CheckedExtendedDeletionReport ==
    { ZeroExtendedDeletionReport }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp6 }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.trdRegTsEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.displayLowQty = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.displayHighQty = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.volumeDiscoveryPrice = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.pegOffsetValueAbs = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.pegOffsetValuePct = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.partyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.exDestinationType = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.partyEnteringFirm = one] : one \in Sample(5) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.pad1 = one] : one \in Sample(1) }

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
    [ pad2             : Sample(2),
      notifHeaderComp  : NotifHeaderComp2,
      pad6             : Sample(6),
      varText          : SampleBytes,
      alignmentPadding : SampleBytes ]

EncodeForcedLogoutNotification(message) ==
    message.pad2
        \o EncodeNotifHeaderComp2(message.notifHeaderComp)
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.pad6
        \o message.varText
        \o message.alignmentPadding

DecodeForcedLogoutNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp2(pad2.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(notifHeaderComp.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET pad6 == ReadBytes(varTextLen.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET varText == ReadBytes(pad6.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2             |-> pad2.value,
         notifHeaderComp  |-> notifHeaderComp.value,
         pad6             |-> pad6.value,
         varText          |-> varText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroForcedLogoutNotification ==
    [ pad2             |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp  |-> ZeroNotifHeaderComp2,
      pad6             |-> [i \in 1 .. 6 |-> 0],
      varText          |-> << >>,
      alignmentPadding |-> << >> ]

(* Forced Logout Notification at zero, then each field in turn at the values it is checked at *)
CheckedForcedLogoutNotification ==
    { ZeroForcedLogoutNotification }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp2 }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroForcedLogoutNotification EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

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
(* Forced User Logout Notification                                         *)
(***************************************************************************)

ForcedUserLogoutNotification ==
    [ pad2             : Sample(2),
      notifHeaderComp  : NotifHeaderComp3,
      userStatus       : Sample(1),
      pad3             : Sample(3),
      username         : Sample(4),
      pad6             : Sample(6),
      varText          : SampleBytes,
      alignmentPadding : SampleBytes ]

EncodeForcedUserLogoutNotification(message) ==
    message.pad2
        \o EncodeNotifHeaderComp3(message.notifHeaderComp)
        \o message.userStatus
        \o message.pad3
        \o message.username
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.pad6
        \o message.varText
        \o message.alignmentPadding

DecodeForcedUserLogoutNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp3(pad2.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET userStatus == ReadBytes(notifHeaderComp.rest, 1) IN IF ~userStatus.ok THEN Fail ELSE
    LET pad3 == ReadBytes(userStatus.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET username == ReadBytes(pad3.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(username.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET pad6 == ReadBytes(varTextLen.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET varText == ReadBytes(pad6.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2             |-> pad2.value,
         notifHeaderComp  |-> notifHeaderComp.value,
         userStatus       |-> userStatus.value,
         pad3             |-> pad3.value,
         username         |-> username.value,
         pad6             |-> pad6.value,
         varText          |-> varText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroForcedUserLogoutNotification ==
    [ pad2             |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp  |-> ZeroNotifHeaderComp3,
      userStatus       |-> [i \in 1 .. 1 |-> 0],
      pad3             |-> [i \in 1 .. 3 |-> 0],
      username         |-> [i \in 1 .. 4 |-> 0],
      pad6             |-> [i \in 1 .. 6 |-> 0],
      varText          |-> << >>,
      alignmentPadding |-> << >> ]

(* Forced User Logout Notification at zero, then each field in turn at the values it is checked at *)
CheckedForcedUserLogoutNotification ==
    { ZeroForcedUserLogoutNotification }
        \cup { [ZeroForcedUserLogoutNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroForcedUserLogoutNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp3 }
        \cup { [ZeroForcedUserLogoutNotification EXCEPT !.userStatus = one] : one \in Sample(1) }
        \cup { [ZeroForcedUserLogoutNotification EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroForcedUserLogoutNotification EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroForcedUserLogoutNotification EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroForcedUserLogoutNotification EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroForcedUserLogoutNotification EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

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
(* Heartbeat Notification: 10 bytes                                        *)
(***************************************************************************)

HeartbeatNotification ==
    [ pad2            : Sample(2),
      notifHeaderComp : NotifHeaderComp4 ]

EncodeHeartbeatNotification(message) ==
    message.pad2
        \o EncodeNotifHeaderComp4(message.notifHeaderComp)

DecodeHeartbeatNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp4(pad2.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    Ok([ pad2            |-> pad2.value,
         notifHeaderComp |-> notifHeaderComp.value ], notifHeaderComp.rest)

ZeroHeartbeatNotification ==
    [ pad2            |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp |-> ZeroNotifHeaderComp4 ]

(* Heartbeat Notification at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatNotification ==
    { ZeroHeartbeatNotification }
        \cup { [ZeroHeartbeatNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroHeartbeatNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp4 }

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
(* Enrichment Rules Grp Comp: 48 bytes                                     *)
(***************************************************************************)

EnrichmentRulesGrpComp ==
    [ enrichmentRuleId : Sample(2),
      freeText1        : Sample(12),
      freeText2        : Sample(12),
      freeText4        : Sample(16),
      pad6             : Sample(6) ]

EncodeEnrichmentRulesGrpComp(message) ==
    message.enrichmentRuleId
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.pad6

DecodeEnrichmentRulesGrpComp(bytes) ==
    LET enrichmentRuleId == ReadBytes(bytes, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(enrichmentRuleId.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET pad6 == ReadBytes(freeText4.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ enrichmentRuleId |-> enrichmentRuleId.value,
         freeText1        |-> freeText1.value,
         freeText2        |-> freeText2.value,
         freeText4        |-> freeText4.value,
         pad6             |-> pad6.value ], pad6.rest)

ZeroEnrichmentRulesGrpComp ==
    [ enrichmentRuleId |-> [i \in 1 .. 2 |-> 0],
      freeText1        |-> [i \in 1 .. 12 |-> 0],
      freeText2        |-> [i \in 1 .. 12 |-> 0],
      freeText4        |-> [i \in 1 .. 16 |-> 0],
      pad6             |-> [i \in 1 .. 6 |-> 0] ]

(* Enrichment Rules Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedEnrichmentRulesGrpComp ==
    { ZeroEnrichmentRulesGrpComp }
        \cup { [ZeroEnrichmentRulesGrpComp EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroEnrichmentRulesGrpComp EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroEnrichmentRulesGrpComp EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroEnrichmentRulesGrpComp EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroEnrichmentRulesGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Enrichment Rules Grp Comp, written one after another *)
RECURSIVE EncodeEnrichmentRulesGrpCompList(_)
EncodeEnrichmentRulesGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEnrichmentRulesGrpComp(Head(messages)) \o EncodeEnrichmentRulesGrpCompList(Tail(messages))

(* As many Enrichment Rules Grp Comp as the field that counts them says *)
RECURSIVE ReadEnrichmentRulesGrpCompList(_, _)
ReadEnrichmentRulesGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeEnrichmentRulesGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEnrichmentRulesGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Enrichment Rules Grp Comp of each kind, for the lists that carry them *)
OneEnrichmentRulesGrpComp == { ZeroEnrichmentRulesGrpComp }

(***************************************************************************)
(* Inquire Enrichment Rule Id List Response                                *)
(***************************************************************************)

InquireEnrichmentRuleIdListResponse ==
    [ pad2                   : Sample(2),
      responseHeaderComp     : ResponseHeaderComp,
      lastEntityProcessed    : Sample(16),
      pad6                   : Sample(6),
      enrichmentRulesGrpComp : SampleLists(OneEnrichmentRulesGrpComp) ]

EncodeInquireEnrichmentRuleIdListResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp(message.responseHeaderComp)
        \o message.lastEntityProcessed
        \o EncodeUIntLE(Len(message.enrichmentRulesGrpComp), 2)
        \o message.pad6
        \o EncodeEnrichmentRulesGrpCompList(message.enrichmentRulesGrpComp)

DecodeInquireEnrichmentRuleIdListResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET lastEntityProcessed == ReadBytes(responseHeaderComp.rest, 16) IN IF ~lastEntityProcessed.ok THEN Fail ELSE
    LET noEnrichmentRules == ReadUIntLE(lastEntityProcessed.rest, 2) IN IF ~noEnrichmentRules.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noEnrichmentRules.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET enrichmentRulesGrpComp == ReadEnrichmentRulesGrpCompList(pad6.rest, noEnrichmentRules.value) IN IF ~enrichmentRulesGrpComp.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         responseHeaderComp     |-> responseHeaderComp.value,
         lastEntityProcessed    |-> lastEntityProcessed.value,
         pad6                   |-> pad6.value,
         enrichmentRulesGrpComp |-> enrichmentRulesGrpComp.value ], enrichmentRulesGrpComp.rest)

ZeroInquireEnrichmentRuleIdListResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp     |-> ZeroResponseHeaderComp,
      lastEntityProcessed    |-> [i \in 1 .. 16 |-> 0],
      pad6                   |-> [i \in 1 .. 6 |-> 0],
      enrichmentRulesGrpComp |-> << >> ]

(* Inquire Enrichment Rule Id List Response at zero, then each field in turn at the values it is checked at *)
CheckedInquireEnrichmentRuleIdListResponse ==
    { ZeroInquireEnrichmentRuleIdListResponse }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.enrichmentRulesGrpComp = one] : one \in SampleLists(OneEnrichmentRulesGrpComp) }

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
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp2,
      pad6               : Sample(6),
      sessionsGrpComp    : SampleLists(OneSessionsGrpComp) ]

EncodeInquireSessionListResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp2(message.responseHeaderComp)
        \o EncodeUIntLE(Len(message.sessionsGrpComp), 2)
        \o message.pad6
        \o EncodeSessionsGrpCompList(message.sessionsGrpComp)

DecodeInquireSessionListResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp2(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET noSessions == ReadUIntLE(responseHeaderComp.rest, 2) IN IF ~noSessions.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noSessions.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET sessionsGrpComp == ReadSessionsGrpCompList(pad6.rest, noSessions.value) IN IF ~sessionsGrpComp.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value,
         pad6               |-> pad6.value,
         sessionsGrpComp    |-> sessionsGrpComp.value ], sessionsGrpComp.rest)

ZeroInquireSessionListResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp2,
      pad6               |-> [i \in 1 .. 6 |-> 0],
      sessionsGrpComp    |-> << >> ]

(* Inquire Session List Response at zero, then each field in turn at the values it is checked at *)
CheckedInquireSessionListResponse ==
    { ZeroInquireSessionListResponse }
        \cup { [ZeroInquireSessionListResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireSessionListResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp2 }
        \cup { [ZeroInquireSessionListResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroInquireSessionListResponse EXCEPT !.sessionsGrpComp = one] : one \in SampleLists(OneSessionsGrpComp) }

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
(* Party Details Grp Comp: 16 bytes                                        *)
(***************************************************************************)

PartyDetailsGrpComp ==
    [ partyDetailIdExecutingTrader : Sample(4),
      partyDetailExecutingTrader   : Sample(6),
      partyDetailRoleQualifier     : Sample(1),
      partyDetailStatus            : Sample(1),
      partyDetailDeskId            : Sample(3),
      pad1                         : Sample(1) ]

EncodePartyDetailsGrpComp(message) ==
    message.partyDetailIdExecutingTrader
        \o message.partyDetailExecutingTrader
        \o message.partyDetailRoleQualifier
        \o message.partyDetailStatus
        \o message.partyDetailDeskId
        \o message.pad1

DecodePartyDetailsGrpComp(bytes) ==
    LET partyDetailIdExecutingTrader == ReadBytes(bytes, 4) IN IF ~partyDetailIdExecutingTrader.ok THEN Fail ELSE
    LET partyDetailExecutingTrader == ReadBytes(partyDetailIdExecutingTrader.rest, 6) IN IF ~partyDetailExecutingTrader.ok THEN Fail ELSE
    LET partyDetailRoleQualifier == ReadBytes(partyDetailExecutingTrader.rest, 1) IN IF ~partyDetailRoleQualifier.ok THEN Fail ELSE
    LET partyDetailStatus == ReadBytes(partyDetailRoleQualifier.rest, 1) IN IF ~partyDetailStatus.ok THEN Fail ELSE
    LET partyDetailDeskId == ReadBytes(partyDetailStatus.rest, 3) IN IF ~partyDetailDeskId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(partyDetailDeskId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ partyDetailIdExecutingTrader |-> partyDetailIdExecutingTrader.value,
         partyDetailExecutingTrader   |-> partyDetailExecutingTrader.value,
         partyDetailRoleQualifier     |-> partyDetailRoleQualifier.value,
         partyDetailStatus            |-> partyDetailStatus.value,
         partyDetailDeskId            |-> partyDetailDeskId.value,
         pad1                         |-> pad1.value ], pad1.rest)

ZeroPartyDetailsGrpComp ==
    [ partyDetailIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      partyDetailExecutingTrader   |-> [i \in 1 .. 6 |-> 0],
      partyDetailRoleQualifier     |-> [i \in 1 .. 1 |-> 0],
      partyDetailStatus            |-> [i \in 1 .. 1 |-> 0],
      partyDetailDeskId            |-> [i \in 1 .. 3 |-> 0],
      pad1                         |-> [i \in 1 .. 1 |-> 0] ]

(* Party Details Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsGrpComp ==
    { ZeroPartyDetailsGrpComp }
        \cup { [ZeroPartyDetailsGrpComp EXCEPT !.partyDetailIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroPartyDetailsGrpComp EXCEPT !.partyDetailExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroPartyDetailsGrpComp EXCEPT !.partyDetailRoleQualifier = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsGrpComp EXCEPT !.partyDetailStatus = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsGrpComp EXCEPT !.partyDetailDeskId = one] : one \in Sample(3) }
        \cup { [ZeroPartyDetailsGrpComp EXCEPT !.pad1 = one] : one \in Sample(1) }

(* A run of Party Details Grp Comp, written one after another *)
RECURSIVE EncodePartyDetailsGrpCompList(_)
EncodePartyDetailsGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartyDetailsGrpComp(Head(messages)) \o EncodePartyDetailsGrpCompList(Tail(messages))

(* As many Party Details Grp Comp as the field that counts them says *)
RECURSIVE ReadPartyDetailsGrpCompList(_, _)
ReadPartyDetailsGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartyDetailsGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartyDetailsGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Party Details Grp Comp of each kind, for the lists that carry them *)
OnePartyDetailsGrpComp == { ZeroPartyDetailsGrpComp }

(***************************************************************************)
(* Inquire User Response                                                   *)
(***************************************************************************)

InquireUserResponse ==
    [ pad2                : Sample(2),
      responseHeaderComp  : ResponseHeaderComp3,
      lastEntityProcessed : Sample(16),
      pad6                : Sample(6),
      partyDetailsGrpComp : SampleLists(OnePartyDetailsGrpComp) ]

EncodeInquireUserResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp3(message.responseHeaderComp)
        \o message.lastEntityProcessed
        \o EncodeUIntLE(Len(message.partyDetailsGrpComp), 2)
        \o message.pad6
        \o EncodePartyDetailsGrpCompList(message.partyDetailsGrpComp)

DecodeInquireUserResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp3(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET lastEntityProcessed == ReadBytes(responseHeaderComp.rest, 16) IN IF ~lastEntityProcessed.ok THEN Fail ELSE
    LET noPartyDetails == ReadUIntLE(lastEntityProcessed.rest, 2) IN IF ~noPartyDetails.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noPartyDetails.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET partyDetailsGrpComp == ReadPartyDetailsGrpCompList(pad6.rest, noPartyDetails.value) IN IF ~partyDetailsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                |-> pad2.value,
         responseHeaderComp  |-> responseHeaderComp.value,
         lastEntityProcessed |-> lastEntityProcessed.value,
         pad6                |-> pad6.value,
         partyDetailsGrpComp |-> partyDetailsGrpComp.value ], partyDetailsGrpComp.rest)

ZeroInquireUserResponse ==
    [ pad2                |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp  |-> ZeroResponseHeaderComp3,
      lastEntityProcessed |-> [i \in 1 .. 16 |-> 0],
      pad6                |-> [i \in 1 .. 6 |-> 0],
      partyDetailsGrpComp |-> << >> ]

(* Inquire User Response at zero, then each field in turn at the values it is checked at *)
CheckedInquireUserResponse ==
    { ZeroInquireUserResponse }
        \cup { [ZeroInquireUserResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireUserResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp3 }
        \cup { [ZeroInquireUserResponse EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }
        \cup { [ZeroInquireUserResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroInquireUserResponse EXCEPT !.partyDetailsGrpComp = one] : one \in SampleLists(OnePartyDetailsGrpComp) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp7 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp7 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Issuer Notification: 122 bytes                                          *)
(***************************************************************************)

IssuerNotification ==
    [ pad2                  : Sample(2),
      rbcHeaderMeComp       : RbcHeaderMeComp7,
      securityId            : Sample(8),
      transactTime          : Sample(8),
      lastPx                : Sample(8),
      potentialExecVolume   : Sample(8),
      lastQty               : Sample(8),
      imbalanceQty          : Sample(8),
      marketSegmentId       : Sample(4),
      partyIdSessionId      : Sample(4),
      securityTradingStatus : Sample(1),
      pad7                  : Sample(7) ]

EncodeIssuerNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp7(message.rbcHeaderMeComp)
        \o message.securityId
        \o message.transactTime
        \o message.lastPx
        \o message.potentialExecVolume
        \o message.lastQty
        \o message.imbalanceQty
        \o message.marketSegmentId
        \o message.partyIdSessionId
        \o message.securityTradingStatus
        \o message.pad7

DecodeIssuerNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp7(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET lastPx == ReadBytes(transactTime.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET potentialExecVolume == ReadBytes(lastPx.rest, 8) IN IF ~potentialExecVolume.ok THEN Fail ELSE
    LET lastQty == ReadBytes(potentialExecVolume.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET imbalanceQty == ReadBytes(lastQty.rest, 8) IN IF ~imbalanceQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(imbalanceQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(partyIdSessionId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET pad7 == ReadBytes(securityTradingStatus.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         rbcHeaderMeComp       |-> rbcHeaderMeComp.value,
         securityId            |-> securityId.value,
         transactTime          |-> transactTime.value,
         lastPx                |-> lastPx.value,
         potentialExecVolume   |-> potentialExecVolume.value,
         lastQty               |-> lastQty.value,
         imbalanceQty          |-> imbalanceQty.value,
         marketSegmentId       |-> marketSegmentId.value,
         partyIdSessionId      |-> partyIdSessionId.value,
         securityTradingStatus |-> securityTradingStatus.value,
         pad7                  |-> pad7.value ], pad7.rest)

ZeroIssuerNotification ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp       |-> ZeroRbcHeaderMeComp7,
      securityId            |-> [i \in 1 .. 8 |-> 0],
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      potentialExecVolume   |-> [i \in 1 .. 8 |-> 0],
      lastQty               |-> [i \in 1 .. 8 |-> 0],
      imbalanceQty          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId      |-> [i \in 1 .. 4 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      pad7                  |-> [i \in 1 .. 7 |-> 0] ]

(* Issuer Notification at zero, then each field in turn at the values it is checked at *)
CheckedIssuerNotification ==
    { ZeroIssuerNotification }
        \cup { [ZeroIssuerNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroIssuerNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp7 }
        \cup { [ZeroIssuerNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroIssuerNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroIssuerNotification EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroIssuerNotification EXCEPT !.potentialExecVolume = one] : one \in Sample(8) }
        \cup { [ZeroIssuerNotification EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroIssuerNotification EXCEPT !.imbalanceQty = one] : one \in Sample(8) }
        \cup { [ZeroIssuerNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroIssuerNotification EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroIssuerNotification EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroIssuerNotification EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp6 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp6(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp6(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp6 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp6 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Issuer Security State Change Response: 58 bytes                         *)
(***************************************************************************)

IssuerSecurityStateChangeResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp6,
      securityStatusReportId : Sample(8) ]

EncodeIssuerSecurityStateChangeResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp6(message.nrResponseHeaderMeComp)
        \o message.securityStatusReportId

DecodeIssuerSecurityStateChangeResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp6(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET securityStatusReportId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~securityStatusReportId.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         securityStatusReportId |-> securityStatusReportId.value ], securityStatusReportId.rest)

ZeroIssuerSecurityStateChangeResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp6,
      securityStatusReportId |-> [i \in 1 .. 8 |-> 0] ]

(* Issuer Security State Change Response at zero, then each field in turn at the values it is checked at *)
CheckedIssuerSecurityStateChangeResponse ==
    { ZeroIssuerSecurityStateChangeResponse }
        \cup { [ZeroIssuerSecurityStateChangeResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroIssuerSecurityStateChangeResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp6 }
        \cup { [ZeroIssuerSecurityStateChangeResponse EXCEPT !.securityStatusReportId = one] : one \in Sample(8) }

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
(* Legal Notification Broadcast                                            *)
(***************************************************************************)

LegalNotificationBroadcast ==
    [ pad2             : Sample(2),
      rbcHeaderComp    : RbcHeaderComp,
      transactTime     : Sample(8),
      userStatus       : Sample(1),
      pad5             : Sample(5),
      varText          : SampleBytes,
      alignmentPadding : SampleBytes ]

EncodeLegalNotificationBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp(message.rbcHeaderComp)
        \o message.transactTime
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.userStatus
        \o message.pad5
        \o message.varText
        \o message.alignmentPadding

DecodeLegalNotificationBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(transactTime.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET userStatus == ReadBytes(varTextLen.rest, 1) IN IF ~userStatus.ok THEN Fail ELSE
    LET pad5 == ReadBytes(userStatus.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    LET varText == ReadBytes(pad5.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2             |-> pad2.value,
         rbcHeaderComp    |-> rbcHeaderComp.value,
         transactTime     |-> transactTime.value,
         userStatus       |-> userStatus.value,
         pad5             |-> pad5.value,
         varText          |-> varText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroLegalNotificationBroadcast ==
    [ pad2             |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp    |-> ZeroRbcHeaderComp,
      transactTime     |-> [i \in 1 .. 8 |-> 0],
      userStatus       |-> [i \in 1 .. 1 |-> 0],
      pad5             |-> [i \in 1 .. 5 |-> 0],
      varText          |-> << >>,
      alignmentPadding |-> << >> ]

(* Legal Notification Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedLegalNotificationBroadcast ==
    { ZeroLegalNotificationBroadcast }
        \cup { [ZeroLegalNotificationBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLegalNotificationBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp }
        \cup { [ZeroLegalNotificationBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroLegalNotificationBroadcast EXCEPT !.userStatus = one] : one \in Sample(1) }
        \cup { [ZeroLegalNotificationBroadcast EXCEPT !.pad5 = one] : one \in Sample(5) }
        \cup { [ZeroLegalNotificationBroadcast EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroLegalNotificationBroadcast EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

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
(* Logon Response: 90 bytes                                                *)
(***************************************************************************)

LogonResponse ==
    [ pad2                    : Sample(2),
      responseHeaderComp      : ResponseHeaderComp4,
      throttleTimeInterval    : Sample(8),
      throttleNoMsgs          : Sample(4),
      throttleDisconnectLimit : Sample(4),
      heartBtInt              : Sample(4),
      sessionInstanceId       : Sample(4),
      marketId                : Sample(2),
      tradSesMode             : Sample(1),
      defaultCstmApplVerId    : Sample(30),
      defaultCstmApplVerSubId : Sample(5),
      pad2v2                  : Sample(2) ]

EncodeLogonResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp4(message.responseHeaderComp)
        \o message.throttleTimeInterval
        \o message.throttleNoMsgs
        \o message.throttleDisconnectLimit
        \o message.heartBtInt
        \o message.sessionInstanceId
        \o message.marketId
        \o message.tradSesMode
        \o message.defaultCstmApplVerId
        \o message.defaultCstmApplVerSubId
        \o message.pad2v2

DecodeLogonResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp4(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET throttleTimeInterval == ReadBytes(responseHeaderComp.rest, 8) IN IF ~throttleTimeInterval.ok THEN Fail ELSE
    LET throttleNoMsgs == ReadBytes(throttleTimeInterval.rest, 4) IN IF ~throttleNoMsgs.ok THEN Fail ELSE
    LET throttleDisconnectLimit == ReadBytes(throttleNoMsgs.rest, 4) IN IF ~throttleDisconnectLimit.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(throttleDisconnectLimit.rest, 4) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET sessionInstanceId == ReadBytes(heartBtInt.rest, 4) IN IF ~sessionInstanceId.ok THEN Fail ELSE
    LET marketId == ReadBytes(sessionInstanceId.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET tradSesMode == ReadBytes(marketId.rest, 1) IN IF ~tradSesMode.ok THEN Fail ELSE
    LET defaultCstmApplVerId == ReadBytes(tradSesMode.rest, 30) IN IF ~defaultCstmApplVerId.ok THEN Fail ELSE
    LET defaultCstmApplVerSubId == ReadBytes(defaultCstmApplVerId.rest, 5) IN IF ~defaultCstmApplVerSubId.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(defaultCstmApplVerSubId.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ pad2                    |-> pad2.value,
         responseHeaderComp      |-> responseHeaderComp.value,
         throttleTimeInterval    |-> throttleTimeInterval.value,
         throttleNoMsgs          |-> throttleNoMsgs.value,
         throttleDisconnectLimit |-> throttleDisconnectLimit.value,
         heartBtInt              |-> heartBtInt.value,
         sessionInstanceId       |-> sessionInstanceId.value,
         marketId                |-> marketId.value,
         tradSesMode             |-> tradSesMode.value,
         defaultCstmApplVerId    |-> defaultCstmApplVerId.value,
         defaultCstmApplVerSubId |-> defaultCstmApplVerSubId.value,
         pad2v2                  |-> pad2v2.value ], pad2v2.rest)

ZeroLogonResponse ==
    [ pad2                    |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp      |-> ZeroResponseHeaderComp4,
      throttleTimeInterval    |-> [i \in 1 .. 8 |-> 0],
      throttleNoMsgs          |-> [i \in 1 .. 4 |-> 0],
      throttleDisconnectLimit |-> [i \in 1 .. 4 |-> 0],
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
        \cup { [ZeroLogonResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp4 }
        \cup { [ZeroLogonResponse EXCEPT !.throttleTimeInterval = one] : one \in Sample(8) }
        \cup { [ZeroLogonResponse EXCEPT !.throttleNoMsgs = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponse EXCEPT !.throttleDisconnectLimit = one] : one \in Sample(4) }
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
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp5 ]

EncodeLogoutResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp5(message.responseHeaderComp)

DecodeLogoutResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp5(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroLogoutResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp5 ]

(* Logout Response at zero, then each field in turn at the values it is checked at *)
CheckedLogoutResponse ==
    { ZeroLogoutResponse }
        \cup { [ZeroLogoutResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogoutResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp5 }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp7 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp7(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp7(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp7 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp7 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Quote Entry Ack Grp Comp: 24 bytes                                      *)
(***************************************************************************)

QuoteEntryAckGrpComp ==
    [ securityId             : Sample(8),
      cxlSize                : Sample(8),
      quoteEntryRejectReason : Sample(4),
      quoteEntryStatus       : Sample(1),
      side                   : Sample(1),
      pad2                   : Sample(2) ]

EncodeQuoteEntryAckGrpComp(message) ==
    message.securityId
        \o message.cxlSize
        \o message.quoteEntryRejectReason
        \o message.quoteEntryStatus
        \o message.side
        \o message.pad2

DecodeQuoteEntryAckGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET cxlSize == ReadBytes(securityId.rest, 8) IN IF ~cxlSize.ok THEN Fail ELSE
    LET quoteEntryRejectReason == ReadBytes(cxlSize.rest, 4) IN IF ~quoteEntryRejectReason.ok THEN Fail ELSE
    LET quoteEntryStatus == ReadBytes(quoteEntryRejectReason.rest, 1) IN IF ~quoteEntryStatus.ok THEN Fail ELSE
    LET side == ReadBytes(quoteEntryStatus.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad2 == ReadBytes(side.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ securityId             |-> securityId.value,
         cxlSize                |-> cxlSize.value,
         quoteEntryRejectReason |-> quoteEntryRejectReason.value,
         quoteEntryStatus       |-> quoteEntryStatus.value,
         side                   |-> side.value,
         pad2                   |-> pad2.value ], pad2.rest)

ZeroQuoteEntryAckGrpComp ==
    [ securityId             |-> [i \in 1 .. 8 |-> 0],
      cxlSize                |-> [i \in 1 .. 8 |-> 0],
      quoteEntryRejectReason |-> [i \in 1 .. 4 |-> 0],
      quoteEntryStatus       |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Entry Ack Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEntryAckGrpComp ==
    { ZeroQuoteEntryAckGrpComp }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.cxlSize = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.quoteEntryRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.quoteEntryStatus = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEntryAckGrpComp EXCEPT !.pad2 = one] : one \in Sample(2) }

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
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp7,
      quoteId                : Sample(8),
      quoteResponseId        : Sample(8),
      marketSegmentId        : Sample(4),
      pad3                   : Sample(3),
      quoteEntryAckGrpComp   : SampleLists(OneQuoteEntryAckGrpComp) ]

EncodeMassQuoteResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp7(message.nrResponseHeaderMeComp)
        \o message.quoteId
        \o message.quoteResponseId
        \o message.marketSegmentId
        \o EncodeUIntBE(Len(message.quoteEntryAckGrpComp), 1)
        \o message.pad3
        \o EncodeQuoteEntryAckGrpCompList(message.quoteEntryAckGrpComp)

DecodeMassQuoteResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp7(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteResponseId == ReadBytes(quoteId.rest, 8) IN IF ~quoteResponseId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteResponseId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET noQuoteSideEntries == ReadUIntBE(marketSegmentId.rest, 1) IN IF ~noQuoteSideEntries.ok THEN Fail ELSE
    LET pad3 == ReadBytes(noQuoteSideEntries.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET quoteEntryAckGrpComp == ReadQuoteEntryAckGrpCompList(pad3.rest, noQuoteSideEntries.value) IN IF ~quoteEntryAckGrpComp.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         quoteId                |-> quoteId.value,
         quoteResponseId        |-> quoteResponseId.value,
         marketSegmentId        |-> marketSegmentId.value,
         pad3                   |-> pad3.value,
         quoteEntryAckGrpComp   |-> quoteEntryAckGrpComp.value ], quoteEntryAckGrpComp.rest)

ZeroMassQuoteResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp7,
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      quoteResponseId        |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0],
      quoteEntryAckGrpComp   |-> << >> ]

(* Mass Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponse ==
    { ZeroMassQuoteResponse }
        \cup { [ZeroMassQuoteResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp7 }
        \cup { [ZeroMassQuoteResponse EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.quoteResponseId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.quoteEntryAckGrpComp = one] : one \in SampleLists(OneQuoteEntryAckGrpComp) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp8 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp8(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp8(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp8 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp8 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Modify Order Nr Response: 146 bytes                                     *)
(***************************************************************************)

ModifyOrderNrResponse ==
    [ pad2                      : Sample(2),
      nrResponseHeaderMeComp    : NrResponseHeaderMeComp8,
      orderId                   : Sample(8),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      securityId                : Sample(8),
      execId                    : Sample(8),
      stopPx                    : Sample(8),
      leavesQty                 : Sample(8),
      cumQty                    : Sample(8),
      cxlQty                    : Sample(8),
      displayQty                : Sample(8),
      orderIdSfx                : Sample(4),
      ordStatus                 : Sample(1),
      execType                  : Sample(1),
      execRestatementReason     : Sample(2),
      crossedIndicator          : Sample(1),
      triggered                 : Sample(1),
      transactionDelayIndicator : Sample(1),
      pad5                      : Sample(5) ]

EncodeModifyOrderNrResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp8(message.nrResponseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.stopPx
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.displayQty
        \o message.orderIdSfx
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.crossedIndicator
        \o message.triggered
        \o message.transactionDelayIndicator
        \o message.pad5

DecodeModifyOrderNrResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp8(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET stopPx == ReadBytes(execId.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(stopPx.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(cxlQty.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(displayQty.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderIdSfx.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(execRestatementReason.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET triggered == ReadBytes(crossedIndicator.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET transactionDelayIndicator == ReadBytes(triggered.rest, 1) IN IF ~transactionDelayIndicator.ok THEN Fail ELSE
    LET pad5 == ReadBytes(transactionDelayIndicator.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ pad2                      |-> pad2.value,
         nrResponseHeaderMeComp    |-> nrResponseHeaderMeComp.value,
         orderId                   |-> orderId.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         securityId                |-> securityId.value,
         execId                    |-> execId.value,
         stopPx                    |-> stopPx.value,
         leavesQty                 |-> leavesQty.value,
         cumQty                    |-> cumQty.value,
         cxlQty                    |-> cxlQty.value,
         displayQty                |-> displayQty.value,
         orderIdSfx                |-> orderIdSfx.value,
         ordStatus                 |-> ordStatus.value,
         execType                  |-> execType.value,
         execRestatementReason     |-> execRestatementReason.value,
         crossedIndicator          |-> crossedIndicator.value,
         triggered                 |-> triggered.value,
         transactionDelayIndicator |-> transactionDelayIndicator.value,
         pad5                      |-> pad5.value ], pad5.rest)

ZeroModifyOrderNrResponse ==
    [ pad2                      |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp    |-> ZeroNrResponseHeaderMeComp8,
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      stopPx                    |-> [i \in 1 .. 8 |-> 0],
      leavesQty                 |-> [i \in 1 .. 8 |-> 0],
      cumQty                    |-> [i \in 1 .. 8 |-> 0],
      cxlQty                    |-> [i \in 1 .. 8 |-> 0],
      displayQty                |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx                |-> [i \in 1 .. 4 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 2 |-> 0],
      crossedIndicator          |-> [i \in 1 .. 1 |-> 0],
      triggered                 |-> [i \in 1 .. 1 |-> 0],
      transactionDelayIndicator |-> [i \in 1 .. 1 |-> 0],
      pad5                      |-> [i \in 1 .. 5 |-> 0] ]

(* Modify Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderNrResponse ==
    { ZeroModifyOrderNrResponse }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp8 }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.transactionDelayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Response Header Me Comp: 64 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp3 ==
    [ requestTime     : Sample(8),
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
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
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
(* Modify Order Response: 170 bytes                                        *)
(***************************************************************************)

ModifyOrderResponse ==
    [ pad2                      : Sample(2),
      responseHeaderMeComp      : ResponseHeaderMeComp3,
      orderId                   : Sample(8),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      securityId                : Sample(8),
      execId                    : Sample(8),
      stopPx                    : Sample(8),
      leavesQty                 : Sample(8),
      cumQty                    : Sample(8),
      cxlQty                    : Sample(8),
      displayQty                : Sample(8),
      trdRegTsTimePriority      : Sample(8),
      orderIdSfx                : Sample(4),
      ordStatus                 : Sample(1),
      execType                  : Sample(1),
      execRestatementReason     : Sample(2),
      crossedIndicator          : Sample(1),
      triggered                 : Sample(1),
      transactionDelayIndicator : Sample(1),
      pad5                      : Sample(5) ]

EncodeModifyOrderResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderMeComp3(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.stopPx
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.displayQty
        \o message.trdRegTsTimePriority
        \o message.orderIdSfx
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.crossedIndicator
        \o message.triggered
        \o message.transactionDelayIndicator
        \o message.pad5

DecodeModifyOrderResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp3(pad2.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET stopPx == ReadBytes(execId.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(stopPx.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(cxlQty.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(displayQty.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(trdRegTsTimePriority.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderIdSfx.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(execRestatementReason.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET triggered == ReadBytes(crossedIndicator.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET transactionDelayIndicator == ReadBytes(triggered.rest, 1) IN IF ~transactionDelayIndicator.ok THEN Fail ELSE
    LET pad5 == ReadBytes(transactionDelayIndicator.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ pad2                      |-> pad2.value,
         responseHeaderMeComp      |-> responseHeaderMeComp.value,
         orderId                   |-> orderId.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         securityId                |-> securityId.value,
         execId                    |-> execId.value,
         stopPx                    |-> stopPx.value,
         leavesQty                 |-> leavesQty.value,
         cumQty                    |-> cumQty.value,
         cxlQty                    |-> cxlQty.value,
         displayQty                |-> displayQty.value,
         trdRegTsTimePriority      |-> trdRegTsTimePriority.value,
         orderIdSfx                |-> orderIdSfx.value,
         ordStatus                 |-> ordStatus.value,
         execType                  |-> execType.value,
         execRestatementReason     |-> execRestatementReason.value,
         crossedIndicator          |-> crossedIndicator.value,
         triggered                 |-> triggered.value,
         transactionDelayIndicator |-> transactionDelayIndicator.value,
         pad5                      |-> pad5.value ], pad5.rest)

ZeroModifyOrderResponse ==
    [ pad2                      |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp      |-> ZeroResponseHeaderMeComp3,
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      stopPx                    |-> [i \in 1 .. 8 |-> 0],
      leavesQty                 |-> [i \in 1 .. 8 |-> 0],
      cumQty                    |-> [i \in 1 .. 8 |-> 0],
      cxlQty                    |-> [i \in 1 .. 8 |-> 0],
      displayQty                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority      |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx                |-> [i \in 1 .. 4 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 2 |-> 0],
      crossedIndicator          |-> [i \in 1 .. 1 |-> 0],
      triggered                 |-> [i \in 1 .. 1 |-> 0],
      transactionDelayIndicator |-> [i \in 1 .. 1 |-> 0],
      pad5                      |-> [i \in 1 .. 5 |-> 0] ]

(* Modify Order Response at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderResponse ==
    { ZeroModifyOrderResponse }
        \cup { [ZeroModifyOrderResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp3 }
        \cup { [ZeroModifyOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.transactionDelayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp9 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp9(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp9(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp9 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp9 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* New Order Nr Response: 98 bytes                                         *)
(***************************************************************************)

NewOrderNrResponse ==
    [ pad2                      : Sample(2),
      nrResponseHeaderMeComp    : NrResponseHeaderMeComp9,
      orderId                   : Sample(8),
      clOrdId                   : Sample(8),
      securityId                : Sample(8),
      execId                    : Sample(8),
      orderIdSfx                : Sample(4),
      ordStatus                 : Sample(1),
      execType                  : Sample(1),
      execRestatementReason     : Sample(2),
      crossedIndicator          : Sample(1),
      triggered                 : Sample(1),
      transactionDelayIndicator : Sample(1),
      pad5                      : Sample(5) ]

EncodeNewOrderNrResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp9(message.nrResponseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.securityId
        \o message.execId
        \o message.orderIdSfx
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.crossedIndicator
        \o message.triggered
        \o message.transactionDelayIndicator
        \o message.pad5

DecodeNewOrderNrResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp9(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(execId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderIdSfx.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(execRestatementReason.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET triggered == ReadBytes(crossedIndicator.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET transactionDelayIndicator == ReadBytes(triggered.rest, 1) IN IF ~transactionDelayIndicator.ok THEN Fail ELSE
    LET pad5 == ReadBytes(transactionDelayIndicator.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ pad2                      |-> pad2.value,
         nrResponseHeaderMeComp    |-> nrResponseHeaderMeComp.value,
         orderId                   |-> orderId.value,
         clOrdId                   |-> clOrdId.value,
         securityId                |-> securityId.value,
         execId                    |-> execId.value,
         orderIdSfx                |-> orderIdSfx.value,
         ordStatus                 |-> ordStatus.value,
         execType                  |-> execType.value,
         execRestatementReason     |-> execRestatementReason.value,
         crossedIndicator          |-> crossedIndicator.value,
         triggered                 |-> triggered.value,
         transactionDelayIndicator |-> transactionDelayIndicator.value,
         pad5                      |-> pad5.value ], pad5.rest)

ZeroNewOrderNrResponse ==
    [ pad2                      |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp    |-> ZeroNrResponseHeaderMeComp9,
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx                |-> [i \in 1 .. 4 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 2 |-> 0],
      crossedIndicator          |-> [i \in 1 .. 1 |-> 0],
      triggered                 |-> [i \in 1 .. 1 |-> 0],
      transactionDelayIndicator |-> [i \in 1 .. 1 |-> 0],
      pad5                      |-> [i \in 1 .. 5 |-> 0] ]

(* New Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderNrResponse ==
    { ZeroNewOrderNrResponse }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp9 }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.transactionDelayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Response Header Me Comp: 64 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp4 ==
    [ requestTime     : Sample(8),
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
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
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
(* New Order Response: 130 bytes                                           *)
(***************************************************************************)

NewOrderResponse ==
    [ pad2                      : Sample(2),
      responseHeaderMeComp      : ResponseHeaderMeComp4,
      orderId                   : Sample(8),
      clOrdId                   : Sample(8),
      securityId                : Sample(8),
      execId                    : Sample(8),
      trdRegTsEntryTime         : Sample(8),
      trdRegTsTimePriority      : Sample(8),
      orderIdSfx                : Sample(4),
      ordStatus                 : Sample(1),
      execType                  : Sample(1),
      execRestatementReason     : Sample(2),
      crossedIndicator          : Sample(1),
      triggered                 : Sample(1),
      transactionDelayIndicator : Sample(1),
      pad5                      : Sample(5) ]

EncodeNewOrderResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderMeComp4(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.securityId
        \o message.execId
        \o message.trdRegTsEntryTime
        \o message.trdRegTsTimePriority
        \o message.orderIdSfx
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.crossedIndicator
        \o message.triggered
        \o message.transactionDelayIndicator
        \o message.pad5

DecodeNewOrderResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp4(pad2.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET trdRegTsEntryTime == ReadBytes(execId.rest, 8) IN IF ~trdRegTsEntryTime.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(trdRegTsEntryTime.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(trdRegTsTimePriority.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderIdSfx.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(execRestatementReason.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET triggered == ReadBytes(crossedIndicator.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET transactionDelayIndicator == ReadBytes(triggered.rest, 1) IN IF ~transactionDelayIndicator.ok THEN Fail ELSE
    LET pad5 == ReadBytes(transactionDelayIndicator.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ pad2                      |-> pad2.value,
         responseHeaderMeComp      |-> responseHeaderMeComp.value,
         orderId                   |-> orderId.value,
         clOrdId                   |-> clOrdId.value,
         securityId                |-> securityId.value,
         execId                    |-> execId.value,
         trdRegTsEntryTime         |-> trdRegTsEntryTime.value,
         trdRegTsTimePriority      |-> trdRegTsTimePriority.value,
         orderIdSfx                |-> orderIdSfx.value,
         ordStatus                 |-> ordStatus.value,
         execType                  |-> execType.value,
         execRestatementReason     |-> execRestatementReason.value,
         crossedIndicator          |-> crossedIndicator.value,
         triggered                 |-> triggered.value,
         transactionDelayIndicator |-> transactionDelayIndicator.value,
         pad5                      |-> pad5.value ], pad5.rest)

ZeroNewOrderResponse ==
    [ pad2                      |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp      |-> ZeroResponseHeaderMeComp4,
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime         |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority      |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx                |-> [i \in 1 .. 4 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 2 |-> 0],
      crossedIndicator          |-> [i \in 1 .. 1 |-> 0],
      triggered                 |-> [i \in 1 .. 1 |-> 0],
      transactionDelayIndicator |-> [i \in 1 .. 1 |-> 0],
      pad5                      |-> [i \in 1 .. 5 |-> 0] ]

(* New Order Response at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderResponse ==
    { ZeroNewOrderResponse }
        \cup { [ZeroNewOrderResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp4 }
        \cup { [ZeroNewOrderResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.trdRegTsEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderResponse EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponse EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponse EXCEPT !.transactionDelayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderResponse EXCEPT !.pad5 = one] : one \in Sample(5) }

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
(* News Broadcast                                                          *)
(***************************************************************************)

NewsBroadcast ==
    [ pad2             : Sample(2),
      rbcHeaderComp    : RbcHeaderComp2,
      origTime         : Sample(8),
      headline         : Sample(256),
      pad6             : Sample(6),
      varText          : SampleBytes,
      alignmentPadding : SampleBytes ]

EncodeNewsBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp2(message.rbcHeaderComp)
        \o message.origTime
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.headline
        \o message.pad6
        \o message.varText
        \o message.alignmentPadding

DecodeNewsBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp2(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET origTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~origTime.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(origTime.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET headline == ReadBytes(varTextLen.rest, 256) IN IF ~headline.ok THEN Fail ELSE
    LET pad6 == ReadBytes(headline.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET varText == ReadBytes(pad6.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2             |-> pad2.value,
         rbcHeaderComp    |-> rbcHeaderComp.value,
         origTime         |-> origTime.value,
         headline         |-> headline.value,
         pad6             |-> pad6.value,
         varText          |-> varText.value,
         alignmentPadding |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroNewsBroadcast ==
    [ pad2             |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp    |-> ZeroRbcHeaderComp2,
      origTime         |-> [i \in 1 .. 8 |-> 0],
      headline         |-> [i \in 1 .. 256 |-> 0],
      pad6             |-> [i \in 1 .. 6 |-> 0],
      varText          |-> << >>,
      alignmentPadding |-> << >> ]

(* News Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedNewsBroadcast ==
    { ZeroNewsBroadcast }
        \cup { [ZeroNewsBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewsBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp2 }
        \cup { [ZeroNewsBroadcast EXCEPT !.origTime = one] : one \in Sample(8) }
        \cup { [ZeroNewsBroadcast EXCEPT !.headline = one] : one \in Sample(256) }
        \cup { [ZeroNewsBroadcast EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroNewsBroadcast EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroNewsBroadcast EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp8 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp8 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Fills Grp Comp: 32 bytes                                                *)
(***************************************************************************)

FillsGrpComp ==
    [ fillPx           : Sample(8),
      fillQty          : Sample(8),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad7             : Sample(7) ]

EncodeFillsGrpComp(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad7

DecodeFillsGrpComp(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 8) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad7 == ReadBytes(fillLiquidityInd.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroFillsGrpComp ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 8 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp ==
    { ZeroFillsGrpComp }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillQty = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillExecId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroFillsGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Order Exec Notification                                                 *)
(***************************************************************************)

OrderExecNotification ==
    [ pad2                  : Sample(2),
      rbcHeaderMeComp       : RbcHeaderMeComp8,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      leavesQty             : Sample(8),
      cumQty                : Sample(8),
      cxlQty                : Sample(8),
      displayQty            : Sample(8),
      marketSegmentId       : Sample(4),
      orderIdSfx            : Sample(4),
      execRestatementReason : Sample(2),
      side                  : Sample(1),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      orderEventType        : Sample(1),
      matchType             : Sample(1),
      triggered             : Sample(1),
      crossedIndicator      : Sample(1),
      fixClOrdId            : Sample(20),
      pad2v2                : Sample(2),
      fillsGrpComp          : SampleLists(OneFillsGrpComp) ]

EncodeOrderExecNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp8(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.displayQty
        \o message.marketSegmentId
        \o message.orderIdSfx
        \o message.execRestatementReason
        \o message.side
        \o message.ordStatus
        \o message.execType
        \o message.orderEventType
        \o message.matchType
        \o message.triggered
        \o message.crossedIndicator
        \o message.fixClOrdId
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.pad2v2
        \o EncodeFillsGrpCompList(message.fillsGrpComp)

DecodeOrderExecNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp8(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(execId.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(cxlQty.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(displayQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(orderIdSfx.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET side == ReadBytes(execRestatementReason.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(side.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET orderEventType == ReadBytes(execType.rest, 1) IN IF ~orderEventType.ok THEN Fail ELSE
    LET matchType == ReadBytes(orderEventType.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET triggered == ReadBytes(matchType.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(triggered.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(crossedIndicator.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(fixClOrdId.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(noFills.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpCompList(pad2v2.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         rbcHeaderMeComp       |-> rbcHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         leavesQty             |-> leavesQty.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         displayQty            |-> displayQty.value,
         marketSegmentId       |-> marketSegmentId.value,
         orderIdSfx            |-> orderIdSfx.value,
         execRestatementReason |-> execRestatementReason.value,
         side                  |-> side.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         orderEventType        |-> orderEventType.value,
         matchType             |-> matchType.value,
         triggered             |-> triggered.value,
         crossedIndicator      |-> crossedIndicator.value,
         fixClOrdId            |-> fixClOrdId.value,
         pad2v2                |-> pad2v2.value,
         fillsGrpComp          |-> fillsGrpComp.value ], fillsGrpComp.rest)

ZeroOrderExecNotification ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp       |-> ZeroRbcHeaderMeComp8,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      leavesQty             |-> [i \in 1 .. 8 |-> 0],
      cumQty                |-> [i \in 1 .. 8 |-> 0],
      cxlQty                |-> [i \in 1 .. 8 |-> 0],
      displayQty            |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      orderEventType        |-> [i \in 1 .. 1 |-> 0],
      matchType             |-> [i \in 1 .. 1 |-> 0],
      triggered             |-> [i \in 1 .. 1 |-> 0],
      crossedIndicator      |-> [i \in 1 .. 1 |-> 0],
      fixClOrdId            |-> [i \in 1 .. 20 |-> 0],
      pad2v2                |-> [i \in 1 .. 2 |-> 0],
      fillsGrpComp          |-> << >> ]

(* Order Exec Notification at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecNotification ==
    { ZeroOrderExecNotification }
        \cup { [ZeroOrderExecNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp8 }
        \cup { [ZeroOrderExecNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.orderEventType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecNotification EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecNotification EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp9 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp9 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Fills Grp Comp: 32 bytes                                                *)
(***************************************************************************)

FillsGrpComp2 ==
    [ fillPx           : Sample(8),
      fillQty          : Sample(8),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad7             : Sample(7) ]

EncodeFillsGrpComp2(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad7

DecodeFillsGrpComp2(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 8) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad7 == ReadBytes(fillLiquidityInd.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroFillsGrpComp2 ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 8 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp2 ==
    { ZeroFillsGrpComp2 }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillQty = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillExecId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Order Exec Report Broadcast                                             *)
(***************************************************************************)

OrderExecReportBroadcast ==
    [ pad2                   : Sample(2),
      rbcHeaderMeComp        : RbcHeaderMeComp9,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      trdRegTsEntryTime      : Sample(8),
      trdRegTsTimePriority   : Sample(8),
      price                  : Sample(8),
      leavesQty              : Sample(8),
      cumQty                 : Sample(8),
      cxlQty                 : Sample(8),
      orderQty               : Sample(8),
      displayQty             : Sample(8),
      displayLowQty          : Sample(8),
      displayHighQty         : Sample(8),
      stopPx                 : Sample(8),
      volumeDiscoveryPrice   : Sample(8),
      pegOffsetValueAbs      : Sample(8),
      pegOffsetValuePct      : Sample(8),
      quoteId                : Sample(8),
      marketSegmentId        : Sample(4),
      orderIdSfx             : Sample(4),
      expireDate             : Sample(4),
      matchInstCrossId       : Sample(4),
      partyIdExecutingUnit   : Sample(4),
      partyIdSessionId       : Sample(4),
      partyIdExecutingTrader : Sample(4),
      partyIdEnteringTrader  : Sample(4),
      execRestatementReason  : Sample(2),
      partyIdEnteringFirm    : Sample(1),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      orderEventType         : Sample(1),
      matchType              : Sample(1),
      side                   : Sample(1),
      ordType                : Sample(1),
      tradingCapacity        : Sample(1),
      timeInForce            : Sample(1),
      execInst               : Sample(1),
      tradingSessionSubId    : Sample(1),
      applSeqIndicator       : Sample(1),
      exDestinationType      : Sample(1),
      partyEnteringFirm      : Sample(5),
      partyEnteringTrader    : Sample(6),
      partyExecutingFirm     : Sample(5),
      partyExecutingTrader   : Sample(6),
      freeText1              : Sample(12),
      freeText2              : Sample(12),
      freeText4              : Sample(16),
      fixClOrdId             : Sample(20),
      triggered              : Sample(1),
      crossedIndicator       : Sample(1),
      pad4                   : Sample(4),
      fillsGrpComp           : SampleLists(OneFillsGrpComp2) ]

EncodeOrderExecReportBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp9(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.trdRegTsEntryTime
        \o message.trdRegTsTimePriority
        \o message.price
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.orderQty
        \o message.displayQty
        \o message.displayLowQty
        \o message.displayHighQty
        \o message.stopPx
        \o message.volumeDiscoveryPrice
        \o message.pegOffsetValueAbs
        \o message.pegOffsetValuePct
        \o message.quoteId
        \o message.marketSegmentId
        \o message.orderIdSfx
        \o message.expireDate
        \o message.matchInstCrossId
        \o message.partyIdExecutingUnit
        \o message.partyIdSessionId
        \o message.partyIdExecutingTrader
        \o message.partyIdEnteringTrader
        \o message.execRestatementReason
        \o message.partyIdEnteringFirm
        \o message.ordStatus
        \o message.execType
        \o message.orderEventType
        \o message.matchType
        \o message.side
        \o message.ordType
        \o message.tradingCapacity
        \o message.timeInForce
        \o message.execInst
        \o message.tradingSessionSubId
        \o message.applSeqIndicator
        \o message.exDestinationType
        \o message.partyEnteringFirm
        \o message.partyEnteringTrader
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.fixClOrdId
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.triggered
        \o message.crossedIndicator
        \o message.pad4
        \o EncodeFillsGrpComp2List(message.fillsGrpComp)

DecodeOrderExecReportBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp9(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET trdRegTsEntryTime == ReadBytes(execId.rest, 8) IN IF ~trdRegTsEntryTime.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(trdRegTsEntryTime.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET price == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(price.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(cxlQty.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(orderQty.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayLowQty == ReadBytes(displayQty.rest, 8) IN IF ~displayLowQty.ok THEN Fail ELSE
    LET displayHighQty == ReadBytes(displayLowQty.rest, 8) IN IF ~displayHighQty.ok THEN Fail ELSE
    LET stopPx == ReadBytes(displayHighQty.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET volumeDiscoveryPrice == ReadBytes(stopPx.rest, 8) IN IF ~volumeDiscoveryPrice.ok THEN Fail ELSE
    LET pegOffsetValueAbs == ReadBytes(volumeDiscoveryPrice.rest, 8) IN IF ~pegOffsetValueAbs.ok THEN Fail ELSE
    LET pegOffsetValuePct == ReadBytes(pegOffsetValueAbs.rest, 8) IN IF ~pegOffsetValuePct.ok THEN Fail ELSE
    LET quoteId == ReadBytes(pegOffsetValuePct.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET expireDate == ReadBytes(orderIdSfx.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(expireDate.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(matchInstCrossId.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(partyIdExecutingUnit.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET partyIdExecutingTrader == ReadBytes(partyIdSessionId.rest, 4) IN IF ~partyIdExecutingTrader.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(partyIdExecutingTrader.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(partyIdEnteringTrader.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(execRestatementReason.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET orderEventType == ReadBytes(execType.rest, 1) IN IF ~orderEventType.ok THEN Fail ELSE
    LET matchType == ReadBytes(orderEventType.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET side == ReadBytes(matchType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(ordType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(tradingCapacity.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(execInst.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET exDestinationType == ReadBytes(applSeqIndicator.rest, 1) IN IF ~exDestinationType.ok THEN Fail ELSE
    LET partyEnteringFirm == ReadBytes(exDestinationType.rest, 5) IN IF ~partyEnteringFirm.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyEnteringFirm.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(partyEnteringTrader.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyExecutingTrader.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(freeText4.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(fixClOrdId.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET triggered == ReadBytes(noFills.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(triggered.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET pad4 == ReadBytes(crossedIndicator.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpComp2List(pad4.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         rbcHeaderMeComp        |-> rbcHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         trdRegTsEntryTime      |-> trdRegTsEntryTime.value,
         trdRegTsTimePriority   |-> trdRegTsTimePriority.value,
         price                  |-> price.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         orderQty               |-> orderQty.value,
         displayQty             |-> displayQty.value,
         displayLowQty          |-> displayLowQty.value,
         displayHighQty         |-> displayHighQty.value,
         stopPx                 |-> stopPx.value,
         volumeDiscoveryPrice   |-> volumeDiscoveryPrice.value,
         pegOffsetValueAbs      |-> pegOffsetValueAbs.value,
         pegOffsetValuePct      |-> pegOffsetValuePct.value,
         quoteId                |-> quoteId.value,
         marketSegmentId        |-> marketSegmentId.value,
         orderIdSfx             |-> orderIdSfx.value,
         expireDate             |-> expireDate.value,
         matchInstCrossId       |-> matchInstCrossId.value,
         partyIdExecutingUnit   |-> partyIdExecutingUnit.value,
         partyIdSessionId       |-> partyIdSessionId.value,
         partyIdExecutingTrader |-> partyIdExecutingTrader.value,
         partyIdEnteringTrader  |-> partyIdEnteringTrader.value,
         execRestatementReason  |-> execRestatementReason.value,
         partyIdEnteringFirm    |-> partyIdEnteringFirm.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         orderEventType         |-> orderEventType.value,
         matchType              |-> matchType.value,
         side                   |-> side.value,
         ordType                |-> ordType.value,
         tradingCapacity        |-> tradingCapacity.value,
         timeInForce            |-> timeInForce.value,
         execInst               |-> execInst.value,
         tradingSessionSubId    |-> tradingSessionSubId.value,
         applSeqIndicator       |-> applSeqIndicator.value,
         exDestinationType      |-> exDestinationType.value,
         partyEnteringFirm      |-> partyEnteringFirm.value,
         partyEnteringTrader    |-> partyEnteringTrader.value,
         partyExecutingFirm     |-> partyExecutingFirm.value,
         partyExecutingTrader   |-> partyExecutingTrader.value,
         freeText1              |-> freeText1.value,
         freeText2              |-> freeText2.value,
         freeText4              |-> freeText4.value,
         fixClOrdId             |-> fixClOrdId.value,
         triggered              |-> triggered.value,
         crossedIndicator       |-> crossedIndicator.value,
         pad4                   |-> pad4.value,
         fillsGrpComp           |-> fillsGrpComp.value ], fillsGrpComp.rest)

ZeroOrderExecReportBroadcast ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp        |-> ZeroRbcHeaderMeComp9,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority   |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      leavesQty              |-> [i \in 1 .. 8 |-> 0],
      cumQty                 |-> [i \in 1 .. 8 |-> 0],
      cxlQty                 |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 8 |-> 0],
      displayQty             |-> [i \in 1 .. 8 |-> 0],
      displayLowQty          |-> [i \in 1 .. 8 |-> 0],
      displayHighQty         |-> [i \in 1 .. 8 |-> 0],
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      volumeDiscoveryPrice   |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValueAbs      |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValuePct      |-> [i \in 1 .. 8 |-> 0],
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx             |-> [i \in 1 .. 4 |-> 0],
      expireDate             |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId       |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingUnit   |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId       |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader  |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0],
      partyIdEnteringFirm    |-> [i \in 1 .. 1 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      orderEventType         |-> [i \in 1 .. 1 |-> 0],
      matchType              |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      ordType                |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity        |-> [i \in 1 .. 1 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId    |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator       |-> [i \in 1 .. 1 |-> 0],
      exDestinationType      |-> [i \in 1 .. 1 |-> 0],
      partyEnteringFirm      |-> [i \in 1 .. 5 |-> 0],
      partyEnteringTrader    |-> [i \in 1 .. 6 |-> 0],
      partyExecutingFirm     |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader   |-> [i \in 1 .. 6 |-> 0],
      freeText1              |-> [i \in 1 .. 12 |-> 0],
      freeText2              |-> [i \in 1 .. 12 |-> 0],
      freeText4              |-> [i \in 1 .. 16 |-> 0],
      fixClOrdId             |-> [i \in 1 .. 20 |-> 0],
      triggered              |-> [i \in 1 .. 1 |-> 0],
      crossedIndicator       |-> [i \in 1 .. 1 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0],
      fillsGrpComp           |-> << >> ]

(* Order Exec Report Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecReportBroadcast ==
    { ZeroOrderExecReportBroadcast }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp9 }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.trdRegTsEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.displayLowQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.displayHighQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.volumeDiscoveryPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pegOffsetValueAbs = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pegOffsetValuePct = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderEventType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.exDestinationType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyEnteringFirm = one] : one \in Sample(5) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp2) }

(***************************************************************************)
(* Response Header Me Comp: 64 bytes                                       *)
(***************************************************************************)

ResponseHeaderMeComp5 ==
    [ requestTime     : Sample(8),
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
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(msgSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applId == ReadBytes(partitionId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(applId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applMsgId.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
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
(* Fills Grp Comp: 32 bytes                                                *)
(***************************************************************************)

FillsGrpComp3 ==
    [ fillPx           : Sample(8),
      fillQty          : Sample(8),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad7             : Sample(7) ]

EncodeFillsGrpComp3(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad7

DecodeFillsGrpComp3(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 8) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad7 == ReadBytes(fillLiquidityInd.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroFillsGrpComp3 ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 8 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp3 ==
    { ZeroFillsGrpComp3 }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillQty = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillExecId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Order Exec Response                                                     *)
(***************************************************************************)

OrderExecResponse ==
    [ pad2                      : Sample(2),
      responseHeaderMeComp      : ResponseHeaderMeComp5,
      orderId                   : Sample(8),
      clOrdId                   : Sample(8),
      origClOrdId               : Sample(8),
      securityId                : Sample(8),
      execId                    : Sample(8),
      trdRegTsEntryTime         : Sample(8),
      trdRegTsTimePriority      : Sample(8),
      leavesQty                 : Sample(8),
      cumQty                    : Sample(8),
      cxlQty                    : Sample(8),
      displayQty                : Sample(8),
      marketSegmentId           : Sample(4),
      orderIdSfx                : Sample(4),
      execRestatementReason     : Sample(2),
      side                      : Sample(1),
      ordStatus                 : Sample(1),
      execType                  : Sample(1),
      matchType                 : Sample(1),
      triggered                 : Sample(1),
      crossedIndicator          : Sample(1),
      transactionDelayIndicator : Sample(1),
      pad6                      : Sample(6),
      fillsGrpComp              : SampleLists(OneFillsGrpComp3) ]

EncodeOrderExecResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderMeComp5(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.trdRegTsEntryTime
        \o message.trdRegTsTimePriority
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.displayQty
        \o message.marketSegmentId
        \o message.orderIdSfx
        \o message.execRestatementReason
        \o message.side
        \o message.ordStatus
        \o message.execType
        \o message.matchType
        \o message.triggered
        \o message.crossedIndicator
        \o message.transactionDelayIndicator
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.pad6
        \o EncodeFillsGrpComp3List(message.fillsGrpComp)

DecodeOrderExecResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp5(pad2.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET trdRegTsEntryTime == ReadBytes(execId.rest, 8) IN IF ~trdRegTsEntryTime.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(trdRegTsEntryTime.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(cxlQty.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(displayQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(orderIdSfx.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET side == ReadBytes(execRestatementReason.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(side.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET matchType == ReadBytes(execType.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET triggered == ReadBytes(matchType.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(triggered.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET transactionDelayIndicator == ReadBytes(crossedIndicator.rest, 1) IN IF ~transactionDelayIndicator.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(transactionDelayIndicator.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noFills.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpComp3List(pad6.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                      |-> pad2.value,
         responseHeaderMeComp      |-> responseHeaderMeComp.value,
         orderId                   |-> orderId.value,
         clOrdId                   |-> clOrdId.value,
         origClOrdId               |-> origClOrdId.value,
         securityId                |-> securityId.value,
         execId                    |-> execId.value,
         trdRegTsEntryTime         |-> trdRegTsEntryTime.value,
         trdRegTsTimePriority      |-> trdRegTsTimePriority.value,
         leavesQty                 |-> leavesQty.value,
         cumQty                    |-> cumQty.value,
         cxlQty                    |-> cxlQty.value,
         displayQty                |-> displayQty.value,
         marketSegmentId           |-> marketSegmentId.value,
         orderIdSfx                |-> orderIdSfx.value,
         execRestatementReason     |-> execRestatementReason.value,
         side                      |-> side.value,
         ordStatus                 |-> ordStatus.value,
         execType                  |-> execType.value,
         matchType                 |-> matchType.value,
         triggered                 |-> triggered.value,
         crossedIndicator          |-> crossedIndicator.value,
         transactionDelayIndicator |-> transactionDelayIndicator.value,
         pad6                      |-> pad6.value,
         fillsGrpComp              |-> fillsGrpComp.value ], fillsGrpComp.rest)

ZeroOrderExecResponse ==
    [ pad2                      |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp      |-> ZeroResponseHeaderMeComp5,
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      clOrdId                   |-> [i \in 1 .. 8 |-> 0],
      origClOrdId               |-> [i \in 1 .. 8 |-> 0],
      securityId                |-> [i \in 1 .. 8 |-> 0],
      execId                    |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime         |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority      |-> [i \in 1 .. 8 |-> 0],
      leavesQty                 |-> [i \in 1 .. 8 |-> 0],
      cumQty                    |-> [i \in 1 .. 8 |-> 0],
      cxlQty                    |-> [i \in 1 .. 8 |-> 0],
      displayQty                |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId           |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx                |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason     |-> [i \in 1 .. 2 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      ordStatus                 |-> [i \in 1 .. 1 |-> 0],
      execType                  |-> [i \in 1 .. 1 |-> 0],
      matchType                 |-> [i \in 1 .. 1 |-> 0],
      triggered                 |-> [i \in 1 .. 1 |-> 0],
      crossedIndicator          |-> [i \in 1 .. 1 |-> 0],
      transactionDelayIndicator |-> [i \in 1 .. 1 |-> 0],
      pad6                      |-> [i \in 1 .. 6 |-> 0],
      fillsGrpComp              |-> << >> ]

(* Order Exec Response at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecResponse ==
    { ZeroOrderExecResponse }
        \cup { [ZeroOrderExecResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp5 }
        \cup { [ZeroOrderExecResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.trdRegTsEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecResponse EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecResponse EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.transactionDelayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecResponse EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp3) }

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
(* Party Action Report: 66 bytes                                           *)
(***************************************************************************)

PartyActionReport ==
    [ pad2                             : Sample(2),
      rbcHeaderComp                    : RbcHeaderComp3,
      transactTime                     : Sample(8),
      tradeDate                        : Sample(4),
      requestingPartyIdExecutingTrader : Sample(4),
      partyIdExecutingUnit             : Sample(4),
      partyIdExecutingTrader           : Sample(4),
      requestingPartyIdExecutingSystem : Sample(4),
      marketId                         : Sample(2),
      partyActionType                  : Sample(1),
      requestingPartyIdEnteringFirm    : Sample(1) ]

EncodePartyActionReport(message) ==
    message.pad2
        \o EncodeRbcHeaderComp3(message.rbcHeaderComp)
        \o message.transactTime
        \o message.tradeDate
        \o message.requestingPartyIdExecutingTrader
        \o message.partyIdExecutingUnit
        \o message.partyIdExecutingTrader
        \o message.requestingPartyIdExecutingSystem
        \o message.marketId
        \o message.partyActionType
        \o message.requestingPartyIdEnteringFirm

DecodePartyActionReport(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp3(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(transactTime.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET requestingPartyIdExecutingTrader == ReadBytes(tradeDate.rest, 4) IN IF ~requestingPartyIdExecutingTrader.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(requestingPartyIdExecutingTrader.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partyIdExecutingTrader == ReadBytes(partyIdExecutingUnit.rest, 4) IN IF ~partyIdExecutingTrader.ok THEN Fail ELSE
    LET requestingPartyIdExecutingSystem == ReadBytes(partyIdExecutingTrader.rest, 4) IN IF ~requestingPartyIdExecutingSystem.ok THEN Fail ELSE
    LET marketId == ReadBytes(requestingPartyIdExecutingSystem.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET partyActionType == ReadBytes(marketId.rest, 1) IN IF ~partyActionType.ok THEN Fail ELSE
    LET requestingPartyIdEnteringFirm == ReadBytes(partyActionType.rest, 1) IN IF ~requestingPartyIdEnteringFirm.ok THEN Fail ELSE
    Ok([ pad2                             |-> pad2.value,
         rbcHeaderComp                    |-> rbcHeaderComp.value,
         transactTime                     |-> transactTime.value,
         tradeDate                        |-> tradeDate.value,
         requestingPartyIdExecutingTrader |-> requestingPartyIdExecutingTrader.value,
         partyIdExecutingUnit             |-> partyIdExecutingUnit.value,
         partyIdExecutingTrader           |-> partyIdExecutingTrader.value,
         requestingPartyIdExecutingSystem |-> requestingPartyIdExecutingSystem.value,
         marketId                         |-> marketId.value,
         partyActionType                  |-> partyActionType.value,
         requestingPartyIdEnteringFirm    |-> requestingPartyIdEnteringFirm.value ], requestingPartyIdEnteringFirm.rest)

ZeroPartyActionReport ==
    [ pad2                             |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                    |-> ZeroRbcHeaderComp3,
      transactTime                     |-> [i \in 1 .. 8 |-> 0],
      tradeDate                        |-> [i \in 1 .. 4 |-> 0],
      requestingPartyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingUnit             |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingTrader           |-> [i \in 1 .. 4 |-> 0],
      requestingPartyIdExecutingSystem |-> [i \in 1 .. 4 |-> 0],
      marketId                         |-> [i \in 1 .. 2 |-> 0],
      partyActionType                  |-> [i \in 1 .. 1 |-> 0],
      requestingPartyIdEnteringFirm    |-> [i \in 1 .. 1 |-> 0] ]

(* Party Action Report at zero, then each field in turn at the values it is checked at *)
CheckedPartyActionReport ==
    { ZeroPartyActionReport }
        \cup { [ZeroPartyActionReport EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroPartyActionReport EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp3 }
        \cup { [ZeroPartyActionReport EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroPartyActionReport EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroPartyActionReport EXCEPT !.requestingPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroPartyActionReport EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroPartyActionReport EXCEPT !.partyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroPartyActionReport EXCEPT !.requestingPartyIdExecutingSystem = one] : one \in Sample(4) }
        \cup { [ZeroPartyActionReport EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroPartyActionReport EXCEPT !.partyActionType = one] : one \in Sample(1) }
        \cup { [ZeroPartyActionReport EXCEPT !.requestingPartyIdEnteringFirm = one] : one \in Sample(1) }

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
(* Party Entitlements Update Report: 82 bytes                              *)
(***************************************************************************)

PartyEntitlementsUpdateReport ==
    [ pad2                             : Sample(2),
      rbcHeaderComp                    : RbcHeaderComp4,
      transactTime                     : Sample(8),
      tradeDate                        : Sample(4),
      partyDetailIdExecutingUnit       : Sample(4),
      requestingPartyIdExecutingSystem : Sample(4),
      marketId                         : Sample(2),
      listUpdateAction                 : Sample(1),
      requestingPartyEnteringFirm      : Sample(9),
      requestingPartyClearingFirm      : Sample(9),
      partyDetailStatus                : Sample(1),
      pad6                             : Sample(6) ]

EncodePartyEntitlementsUpdateReport(message) ==
    message.pad2
        \o EncodeRbcHeaderComp4(message.rbcHeaderComp)
        \o message.transactTime
        \o message.tradeDate
        \o message.partyDetailIdExecutingUnit
        \o message.requestingPartyIdExecutingSystem
        \o message.marketId
        \o message.listUpdateAction
        \o message.requestingPartyEnteringFirm
        \o message.requestingPartyClearingFirm
        \o message.partyDetailStatus
        \o message.pad6

DecodePartyEntitlementsUpdateReport(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp4(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(transactTime.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET partyDetailIdExecutingUnit == ReadBytes(tradeDate.rest, 4) IN IF ~partyDetailIdExecutingUnit.ok THEN Fail ELSE
    LET requestingPartyIdExecutingSystem == ReadBytes(partyDetailIdExecutingUnit.rest, 4) IN IF ~requestingPartyIdExecutingSystem.ok THEN Fail ELSE
    LET marketId == ReadBytes(requestingPartyIdExecutingSystem.rest, 2) IN IF ~marketId.ok THEN Fail ELSE
    LET listUpdateAction == ReadBytes(marketId.rest, 1) IN IF ~listUpdateAction.ok THEN Fail ELSE
    LET requestingPartyEnteringFirm == ReadBytes(listUpdateAction.rest, 9) IN IF ~requestingPartyEnteringFirm.ok THEN Fail ELSE
    LET requestingPartyClearingFirm == ReadBytes(requestingPartyEnteringFirm.rest, 9) IN IF ~requestingPartyClearingFirm.ok THEN Fail ELSE
    LET partyDetailStatus == ReadBytes(requestingPartyClearingFirm.rest, 1) IN IF ~partyDetailStatus.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyDetailStatus.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                             |-> pad2.value,
         rbcHeaderComp                    |-> rbcHeaderComp.value,
         transactTime                     |-> transactTime.value,
         tradeDate                        |-> tradeDate.value,
         partyDetailIdExecutingUnit       |-> partyDetailIdExecutingUnit.value,
         requestingPartyIdExecutingSystem |-> requestingPartyIdExecutingSystem.value,
         marketId                         |-> marketId.value,
         listUpdateAction                 |-> listUpdateAction.value,
         requestingPartyEnteringFirm      |-> requestingPartyEnteringFirm.value,
         requestingPartyClearingFirm      |-> requestingPartyClearingFirm.value,
         partyDetailStatus                |-> partyDetailStatus.value,
         pad6                             |-> pad6.value ], pad6.rest)

ZeroPartyEntitlementsUpdateReport ==
    [ pad2                             |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                    |-> ZeroRbcHeaderComp4,
      transactTime                     |-> [i \in 1 .. 8 |-> 0],
      tradeDate                        |-> [i \in 1 .. 4 |-> 0],
      partyDetailIdExecutingUnit       |-> [i \in 1 .. 4 |-> 0],
      requestingPartyIdExecutingSystem |-> [i \in 1 .. 4 |-> 0],
      marketId                         |-> [i \in 1 .. 2 |-> 0],
      listUpdateAction                 |-> [i \in 1 .. 1 |-> 0],
      requestingPartyEnteringFirm      |-> [i \in 1 .. 9 |-> 0],
      requestingPartyClearingFirm      |-> [i \in 1 .. 9 |-> 0],
      partyDetailStatus                |-> [i \in 1 .. 1 |-> 0],
      pad6                             |-> [i \in 1 .. 6 |-> 0] ]

(* Party Entitlements Update Report at zero, then each field in turn at the values it is checked at *)
CheckedPartyEntitlementsUpdateReport ==
    { ZeroPartyEntitlementsUpdateReport }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp4 }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.partyDetailIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.requestingPartyIdExecutingSystem = one] : one \in Sample(4) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.marketId = one] : one \in Sample(2) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.listUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.requestingPartyEnteringFirm = one] : one \in Sample(9) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.requestingPartyClearingFirm = one] : one \in Sample(9) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.partyDetailStatus = one] : one \in Sample(1) }
        \cup { [ZeroPartyEntitlementsUpdateReport EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp10 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
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
        \o message.notificationIn
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
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
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
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
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
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp10 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Not Affected Securities Grp Comp: 8 bytes                               *)
(***************************************************************************)

NotAffectedSecuritiesGrpComp3 ==
    [ notAffectedSecurityId : Sample(8) ]

EncodeNotAffectedSecuritiesGrpComp3(message) ==
    message.notAffectedSecurityId

DecodeNotAffectedSecuritiesGrpComp3(bytes) ==
    LET notAffectedSecurityId == ReadBytes(bytes, 8) IN IF ~notAffectedSecurityId.ok THEN Fail ELSE
    Ok([ notAffectedSecurityId |-> notAffectedSecurityId.value ], notAffectedSecurityId.rest)

ZeroNotAffectedSecuritiesGrpComp3 ==
    [ notAffectedSecurityId |-> [i \in 1 .. 8 |-> 0] ]

(* Not Affected Securities Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotAffectedSecuritiesGrpComp3 ==
    { ZeroNotAffectedSecuritiesGrpComp3 }
        \cup { [ZeroNotAffectedSecuritiesGrpComp3 EXCEPT !.notAffectedSecurityId = one] : one \in Sample(8) }

(* A run of Not Affected Securities Grp Comp, written one after another *)
RECURSIVE EncodeNotAffectedSecuritiesGrpComp3List(_)
EncodeNotAffectedSecuritiesGrpComp3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNotAffectedSecuritiesGrpComp3(Head(messages)) \o EncodeNotAffectedSecuritiesGrpComp3List(Tail(messages))

(* As many Not Affected Securities Grp Comp as the field that counts them says *)
RECURSIVE ReadNotAffectedSecuritiesGrpComp3List(_, _)
ReadNotAffectedSecuritiesGrpComp3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNotAffectedSecuritiesGrpComp3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNotAffectedSecuritiesGrpComp3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Not Affected Securities Grp Comp of each kind, for the lists that carry them *)
OneNotAffectedSecuritiesGrpComp3 == { ZeroNotAffectedSecuritiesGrpComp3 }

(***************************************************************************)
(* Quote Activation Notification                                           *)
(***************************************************************************)

QuoteActivationNotification ==
    [ pad2                         : Sample(2),
      rbcHeaderMeComp              : RbcHeaderMeComp10,
      massActionReportId           : Sample(8),
      marketSegmentId              : Sample(4),
      partyIdEnteringTrader        : Sample(4),
      partyIdEnteringFirm          : Sample(1),
      massActionType               : Sample(1),
      massActionReason             : Sample(1),
      pad3                         : Sample(3),
      notAffectedSecuritiesGrpComp : SampleLists(OneNotAffectedSecuritiesGrpComp3) ]

EncodeQuoteActivationNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp10(message.rbcHeaderMeComp)
        \o message.massActionReportId
        \o message.marketSegmentId
        \o message.partyIdEnteringTrader
        \o EncodeUIntLE(Len(message.notAffectedSecuritiesGrpComp), 2)
        \o message.partyIdEnteringFirm
        \o message.massActionType
        \o message.massActionReason
        \o message.pad3
        \o EncodeNotAffectedSecuritiesGrpComp3List(message.notAffectedSecuritiesGrpComp)

DecodeQuoteActivationNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp10(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(massActionReportId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(marketSegmentId.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET noNotAffectedSecurities == ReadUIntLE(partyIdEnteringTrader.rest, 2) IN IF ~noNotAffectedSecurities.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(noNotAffectedSecurities.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET massActionType == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~massActionType.ok THEN Fail ELSE
    LET massActionReason == ReadBytes(massActionType.rest, 1) IN IF ~massActionReason.ok THEN Fail ELSE
    LET pad3 == ReadBytes(massActionReason.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET notAffectedSecuritiesGrpComp == ReadNotAffectedSecuritiesGrpComp3List(pad3.rest, noNotAffectedSecurities.value) IN IF ~notAffectedSecuritiesGrpComp.ok THEN Fail ELSE
    Ok([ pad2                         |-> pad2.value,
         rbcHeaderMeComp              |-> rbcHeaderMeComp.value,
         massActionReportId           |-> massActionReportId.value,
         marketSegmentId              |-> marketSegmentId.value,
         partyIdEnteringTrader        |-> partyIdEnteringTrader.value,
         partyIdEnteringFirm          |-> partyIdEnteringFirm.value,
         massActionType               |-> massActionType.value,
         massActionReason             |-> massActionReason.value,
         pad3                         |-> pad3.value,
         notAffectedSecuritiesGrpComp |-> notAffectedSecuritiesGrpComp.value ], notAffectedSecuritiesGrpComp.rest)

ZeroQuoteActivationNotification ==
    [ pad2                         |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp              |-> ZeroRbcHeaderMeComp10,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId              |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader        |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringFirm          |-> [i \in 1 .. 1 |-> 0],
      massActionType               |-> [i \in 1 .. 1 |-> 0],
      massActionReason             |-> [i \in 1 .. 1 |-> 0],
      pad3                         |-> [i \in 1 .. 3 |-> 0],
      notAffectedSecuritiesGrpComp |-> << >> ]

(* Quote Activation Notification at zero, then each field in turn at the values it is checked at *)
CheckedQuoteActivationNotification ==
    { ZeroQuoteActivationNotification }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp10 }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.massActionType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.massActionReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.notAffectedSecuritiesGrpComp = one] : one \in SampleLists(OneNotAffectedSecuritiesGrpComp3) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp10 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp10(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp10(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp10 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp10 ==
    { ZeroNrResponseHeaderMeComp10 }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Not Affected Securities Grp Comp: 8 bytes                               *)
(***************************************************************************)

NotAffectedSecuritiesGrpComp4 ==
    [ notAffectedSecurityId : Sample(8) ]

EncodeNotAffectedSecuritiesGrpComp4(message) ==
    message.notAffectedSecurityId

DecodeNotAffectedSecuritiesGrpComp4(bytes) ==
    LET notAffectedSecurityId == ReadBytes(bytes, 8) IN IF ~notAffectedSecurityId.ok THEN Fail ELSE
    Ok([ notAffectedSecurityId |-> notAffectedSecurityId.value ], notAffectedSecurityId.rest)

ZeroNotAffectedSecuritiesGrpComp4 ==
    [ notAffectedSecurityId |-> [i \in 1 .. 8 |-> 0] ]

(* Not Affected Securities Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotAffectedSecuritiesGrpComp4 ==
    { ZeroNotAffectedSecuritiesGrpComp4 }
        \cup { [ZeroNotAffectedSecuritiesGrpComp4 EXCEPT !.notAffectedSecurityId = one] : one \in Sample(8) }

(* A run of Not Affected Securities Grp Comp, written one after another *)
RECURSIVE EncodeNotAffectedSecuritiesGrpComp4List(_)
EncodeNotAffectedSecuritiesGrpComp4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNotAffectedSecuritiesGrpComp4(Head(messages)) \o EncodeNotAffectedSecuritiesGrpComp4List(Tail(messages))

(* As many Not Affected Securities Grp Comp as the field that counts them says *)
RECURSIVE ReadNotAffectedSecuritiesGrpComp4List(_, _)
ReadNotAffectedSecuritiesGrpComp4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNotAffectedSecuritiesGrpComp4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNotAffectedSecuritiesGrpComp4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Not Affected Securities Grp Comp of each kind, for the lists that carry them *)
OneNotAffectedSecuritiesGrpComp4 == { ZeroNotAffectedSecuritiesGrpComp4 }

(***************************************************************************)
(* Quote Activation Response                                               *)
(***************************************************************************)

QuoteActivationResponse ==
    [ pad2                         : Sample(2),
      nrResponseHeaderMeComp       : NrResponseHeaderMeComp10,
      massActionReportId           : Sample(8),
      pad6                         : Sample(6),
      notAffectedSecuritiesGrpComp : SampleLists(OneNotAffectedSecuritiesGrpComp4) ]

EncodeQuoteActivationResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp10(message.nrResponseHeaderMeComp)
        \o message.massActionReportId
        \o EncodeUIntLE(Len(message.notAffectedSecuritiesGrpComp), 2)
        \o message.pad6
        \o EncodeNotAffectedSecuritiesGrpComp4List(message.notAffectedSecuritiesGrpComp)

DecodeQuoteActivationResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp10(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET noNotAffectedSecurities == ReadUIntLE(massActionReportId.rest, 2) IN IF ~noNotAffectedSecurities.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noNotAffectedSecurities.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET notAffectedSecuritiesGrpComp == ReadNotAffectedSecuritiesGrpComp4List(pad6.rest, noNotAffectedSecurities.value) IN IF ~notAffectedSecuritiesGrpComp.ok THEN Fail ELSE
    Ok([ pad2                         |-> pad2.value,
         nrResponseHeaderMeComp       |-> nrResponseHeaderMeComp.value,
         massActionReportId           |-> massActionReportId.value,
         pad6                         |-> pad6.value,
         notAffectedSecuritiesGrpComp |-> notAffectedSecuritiesGrpComp.value ], notAffectedSecuritiesGrpComp.rest)

ZeroQuoteActivationResponse ==
    [ pad2                         |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp       |-> ZeroNrResponseHeaderMeComp10,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      pad6                         |-> [i \in 1 .. 6 |-> 0],
      notAffectedSecuritiesGrpComp |-> << >> ]

(* Quote Activation Response at zero, then each field in turn at the values it is checked at *)
CheckedQuoteActivationResponse ==
    { ZeroQuoteActivationResponse }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp10 }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.notAffectedSecuritiesGrpComp = one] : one \in SampleLists(OneNotAffectedSecuritiesGrpComp4) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp11 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp11(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp11(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp11 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp11 ==
    { ZeroRbcHeaderMeComp11 }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp11 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Quote Event Grp Comp: 48 bytes                                          *)
(***************************************************************************)

QuoteEventGrpComp ==
    [ securityId             : Sample(8),
      quoteEventPx           : Sample(8),
      quoteEventQty          : Sample(8),
      quoteMsgId             : Sample(8),
      quoteEventMatchId      : Sample(4),
      quoteEventExecId       : Sample(4),
      quoteEventType         : Sample(1),
      quoteEventSide         : Sample(1),
      quoteEventLiquidityInd : Sample(1),
      quoteEventReason       : Sample(1),
      pad4                   : Sample(4) ]

EncodeQuoteEventGrpComp(message) ==
    message.securityId
        \o message.quoteEventPx
        \o message.quoteEventQty
        \o message.quoteMsgId
        \o message.quoteEventMatchId
        \o message.quoteEventExecId
        \o message.quoteEventType
        \o message.quoteEventSide
        \o message.quoteEventLiquidityInd
        \o message.quoteEventReason
        \o message.pad4

DecodeQuoteEventGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteEventPx == ReadBytes(securityId.rest, 8) IN IF ~quoteEventPx.ok THEN Fail ELSE
    LET quoteEventQty == ReadBytes(quoteEventPx.rest, 8) IN IF ~quoteEventQty.ok THEN Fail ELSE
    LET quoteMsgId == ReadBytes(quoteEventQty.rest, 8) IN IF ~quoteMsgId.ok THEN Fail ELSE
    LET quoteEventMatchId == ReadBytes(quoteMsgId.rest, 4) IN IF ~quoteEventMatchId.ok THEN Fail ELSE
    LET quoteEventExecId == ReadBytes(quoteEventMatchId.rest, 4) IN IF ~quoteEventExecId.ok THEN Fail ELSE
    LET quoteEventType == ReadBytes(quoteEventExecId.rest, 1) IN IF ~quoteEventType.ok THEN Fail ELSE
    LET quoteEventSide == ReadBytes(quoteEventType.rest, 1) IN IF ~quoteEventSide.ok THEN Fail ELSE
    LET quoteEventLiquidityInd == ReadBytes(quoteEventSide.rest, 1) IN IF ~quoteEventLiquidityInd.ok THEN Fail ELSE
    LET quoteEventReason == ReadBytes(quoteEventLiquidityInd.rest, 1) IN IF ~quoteEventReason.ok THEN Fail ELSE
    LET pad4 == ReadBytes(quoteEventReason.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ securityId             |-> securityId.value,
         quoteEventPx           |-> quoteEventPx.value,
         quoteEventQty          |-> quoteEventQty.value,
         quoteMsgId             |-> quoteMsgId.value,
         quoteEventMatchId      |-> quoteEventMatchId.value,
         quoteEventExecId       |-> quoteEventExecId.value,
         quoteEventType         |-> quoteEventType.value,
         quoteEventSide         |-> quoteEventSide.value,
         quoteEventLiquidityInd |-> quoteEventLiquidityInd.value,
         quoteEventReason       |-> quoteEventReason.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroQuoteEventGrpComp ==
    [ securityId             |-> [i \in 1 .. 8 |-> 0],
      quoteEventPx           |-> [i \in 1 .. 8 |-> 0],
      quoteEventQty          |-> [i \in 1 .. 8 |-> 0],
      quoteMsgId             |-> [i \in 1 .. 8 |-> 0],
      quoteEventMatchId      |-> [i \in 1 .. 4 |-> 0],
      quoteEventExecId       |-> [i \in 1 .. 4 |-> 0],
      quoteEventType         |-> [i \in 1 .. 1 |-> 0],
      quoteEventSide         |-> [i \in 1 .. 1 |-> 0],
      quoteEventLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      quoteEventReason       |-> [i \in 1 .. 1 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Event Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEventGrpComp ==
    { ZeroQuoteEventGrpComp }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventQty = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteMsgId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventMatchId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventSide = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

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
(* Quote Execution Report                                                  *)
(***************************************************************************)

QuoteExecutionReport ==
    [ pad2              : Sample(2),
      rbcHeaderMeComp   : RbcHeaderMeComp11,
      execId            : Sample(8),
      marketSegmentId   : Sample(4),
      pad3              : Sample(3),
      quoteEventGrpComp : SampleLists(OneQuoteEventGrpComp) ]

EncodeQuoteExecutionReport(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp11(message.rbcHeaderMeComp)
        \o message.execId
        \o message.marketSegmentId
        \o EncodeUIntBE(Len(message.quoteEventGrpComp), 1)
        \o message.pad3
        \o EncodeQuoteEventGrpCompList(message.quoteEventGrpComp)

DecodeQuoteExecutionReport(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp11(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET execId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(execId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET noQuoteEvents == ReadUIntBE(marketSegmentId.rest, 1) IN IF ~noQuoteEvents.ok THEN Fail ELSE
    LET pad3 == ReadBytes(noQuoteEvents.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET quoteEventGrpComp == ReadQuoteEventGrpCompList(pad3.rest, noQuoteEvents.value) IN IF ~quoteEventGrpComp.ok THEN Fail ELSE
    Ok([ pad2              |-> pad2.value,
         rbcHeaderMeComp   |-> rbcHeaderMeComp.value,
         execId            |-> execId.value,
         marketSegmentId   |-> marketSegmentId.value,
         pad3              |-> pad3.value,
         quoteEventGrpComp |-> quoteEventGrpComp.value ], quoteEventGrpComp.rest)

ZeroQuoteExecutionReport ==
    [ pad2              |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp   |-> ZeroRbcHeaderMeComp11,
      execId            |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      pad3              |-> [i \in 1 .. 3 |-> 0],
      quoteEventGrpComp |-> << >> ]

(* Quote Execution Report at zero, then each field in turn at the values it is checked at *)
CheckedQuoteExecutionReport ==
    { ZeroQuoteExecutionReport }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp11 }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.quoteEventGrpComp = one] : one \in SampleLists(OneQuoteEventGrpComp) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp12 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp12(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp12(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp12 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp12 ==
    { ZeroRbcHeaderMeComp12 }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp12 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Rfq Broadcast: 98 bytes                                                 *)
(***************************************************************************)

RfqBroadcast ==
    [ pad2               : Sample(2),
      rbcHeaderMeComp    : RbcHeaderMeComp12,
      securityId         : Sample(8),
      execId             : Sample(8),
      orderQty           : Sample(8),
      marketSegmentId    : Sample(4),
      side               : Sample(1),
      partyExecutingFirm : Sample(5),
      pad6               : Sample(6) ]

EncodeRfqBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp12(message.rbcHeaderMeComp)
        \o message.securityId
        \o message.execId
        \o message.orderQty
        \o message.marketSegmentId
        \o message.side
        \o message.partyExecutingFirm
        \o message.pad6

DecodeRfqBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp12(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(execId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET side == ReadBytes(marketSegmentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         rbcHeaderMeComp    |-> rbcHeaderMeComp.value,
         securityId         |-> securityId.value,
         execId             |-> execId.value,
         orderQty           |-> orderQty.value,
         marketSegmentId    |-> marketSegmentId.value,
         side               |-> side.value,
         partyExecutingFirm |-> partyExecutingFirm.value,
         pad6               |-> pad6.value ], pad6.rest)

ZeroRfqBroadcast ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp    |-> ZeroRbcHeaderMeComp12,
      securityId         |-> [i \in 1 .. 8 |-> 0],
      execId             |-> [i \in 1 .. 8 |-> 0],
      orderQty           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm |-> [i \in 1 .. 5 |-> 0],
      pad6               |-> [i \in 1 .. 6 |-> 0] ]

(* Rfq Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedRfqBroadcast ==
    { ZeroRfqBroadcast }
        \cup { [ZeroRfqBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp12 }
        \cup { [ZeroRfqBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRfqBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroRfqBroadcast EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroRfqBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRfqBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRfqBroadcast EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroRfqBroadcast EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp13 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp13(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp13(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp13 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp13 ==
    { ZeroRbcHeaderMeComp13 }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp13 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Rfq Reject Notification: 98 bytes                                       *)
(***************************************************************************)

RfqRejectNotification ==
    [ pad2                     : Sample(2),
      rbcHeaderMeComp          : RbcHeaderMeComp13,
      securityId               : Sample(8),
      execId                   : Sample(8),
      quoteId                  : Sample(8),
      marketSegmentId          : Sample(4),
      quoteRequestRejectReason : Sample(1),
      partyExecutingFirm       : Sample(5),
      pad6                     : Sample(6) ]

EncodeRfqRejectNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp13(message.rbcHeaderMeComp)
        \o message.securityId
        \o message.execId
        \o message.quoteId
        \o message.marketSegmentId
        \o message.quoteRequestRejectReason
        \o message.partyExecutingFirm
        \o message.pad6

DecodeRfqRejectNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp13(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(execId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET quoteRequestRejectReason == ReadBytes(marketSegmentId.rest, 1) IN IF ~quoteRequestRejectReason.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(quoteRequestRejectReason.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                     |-> pad2.value,
         rbcHeaderMeComp          |-> rbcHeaderMeComp.value,
         securityId               |-> securityId.value,
         execId                   |-> execId.value,
         quoteId                  |-> quoteId.value,
         marketSegmentId          |-> marketSegmentId.value,
         quoteRequestRejectReason |-> quoteRequestRejectReason.value,
         partyExecutingFirm       |-> partyExecutingFirm.value,
         pad6                     |-> pad6.value ], pad6.rest)

ZeroRfqRejectNotification ==
    [ pad2                     |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp          |-> ZeroRbcHeaderMeComp13,
      securityId               |-> [i \in 1 .. 8 |-> 0],
      execId                   |-> [i \in 1 .. 8 |-> 0],
      quoteId                  |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId          |-> [i \in 1 .. 4 |-> 0],
      quoteRequestRejectReason |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm       |-> [i \in 1 .. 5 |-> 0],
      pad6                     |-> [i \in 1 .. 6 |-> 0] ]

(* Rfq Reject Notification at zero, then each field in turn at the values it is checked at *)
CheckedRfqRejectNotification ==
    { ZeroRfqRejectNotification }
        \cup { [ZeroRfqRejectNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqRejectNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp13 }
        \cup { [ZeroRfqRejectNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRejectNotification EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRejectNotification EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRejectNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRfqRejectNotification EXCEPT !.quoteRequestRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroRfqRejectNotification EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroRfqRejectNotification EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp11 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp11(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp11(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp11 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp11 ==
    { ZeroNrResponseHeaderMeComp11 }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Rfq Response: 58 bytes                                                  *)
(***************************************************************************)

RfqResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp11,
      execId                 : Sample(8) ]

EncodeRfqResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp11(message.nrResponseHeaderMeComp)
        \o message.execId

DecodeRfqResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp11(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET execId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         execId                 |-> execId.value ], execId.rest)

ZeroRfqResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp11,
      execId                 |-> [i \in 1 .. 8 |-> 0] ]

(* Rfq Response at zero, then each field in turn at the values it is checked at *)
CheckedRfqResponse ==
    { ZeroRfqResponse }
        \cup { [ZeroRfqResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp11 }
        \cup { [ZeroRfqResponse EXCEPT !.execId = one] : one \in Sample(8) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp14 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp14(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp14(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp14 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp14 ==
    { ZeroRbcHeaderMeComp14 }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp14 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Rfq Specialist Broadcast: 106 bytes                                     *)
(***************************************************************************)

RfqSpecialistBroadcast ==
    [ pad2               : Sample(2),
      rbcHeaderMeComp    : RbcHeaderMeComp14,
      securityId         : Sample(8),
      execId             : Sample(8),
      orderQty           : Sample(8),
      quoteId            : Sample(8),
      marketSegmentId    : Sample(4),
      side               : Sample(1),
      partyExecutingFirm : Sample(5),
      pad6               : Sample(6) ]

EncodeRfqSpecialistBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp14(message.rbcHeaderMeComp)
        \o message.securityId
        \o message.execId
        \o message.orderQty
        \o message.quoteId
        \o message.marketSegmentId
        \o message.side
        \o message.partyExecutingFirm
        \o message.pad6

DecodeRfqSpecialistBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp14(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(execId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET quoteId == ReadBytes(orderQty.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET side == ReadBytes(marketSegmentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         rbcHeaderMeComp    |-> rbcHeaderMeComp.value,
         securityId         |-> securityId.value,
         execId             |-> execId.value,
         orderQty           |-> orderQty.value,
         quoteId            |-> quoteId.value,
         marketSegmentId    |-> marketSegmentId.value,
         side               |-> side.value,
         partyExecutingFirm |-> partyExecutingFirm.value,
         pad6               |-> pad6.value ], pad6.rest)

ZeroRfqSpecialistBroadcast ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp    |-> ZeroRbcHeaderMeComp14,
      securityId         |-> [i \in 1 .. 8 |-> 0],
      execId             |-> [i \in 1 .. 8 |-> 0],
      orderQty           |-> [i \in 1 .. 8 |-> 0],
      quoteId            |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm |-> [i \in 1 .. 5 |-> 0],
      pad6               |-> [i \in 1 .. 6 |-> 0] ]

(* Rfq Specialist Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedRfqSpecialistBroadcast ==
    { ZeroRfqSpecialistBroadcast }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp14 }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroRfqSpecialistBroadcast EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp12 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp12(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp12(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp12 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp12 ==
    { ZeroNrResponseHeaderMeComp12 }
        \cup { [ZeroNrResponseHeaderMeComp12 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp12 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp12 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp12 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp12 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp12 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp12 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp12 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Reject                                                                  *)
(***************************************************************************)

Reject ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp12,
      sessionRejectReason    : Sample(4),
      sessionStatus          : Sample(1),
      pad1                   : Sample(1),
      varText                : SampleBytes,
      alignmentPadding       : SampleBytes ]

EncodeReject(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp12(message.nrResponseHeaderMeComp)
        \o message.sessionRejectReason
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.sessionStatus
        \o message.pad1
        \o message.varText
        \o message.alignmentPadding

DecodeReject(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp12(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET sessionRejectReason == ReadBytes(nrResponseHeaderMeComp.rest, 4) IN IF ~sessionRejectReason.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(sessionRejectReason.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET sessionStatus == ReadBytes(varTextLen.rest, 1) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET pad1 == ReadBytes(sessionStatus.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET varText == ReadBytes(pad1.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         sessionRejectReason    |-> sessionRejectReason.value,
         sessionStatus          |-> sessionStatus.value,
         pad1                   |-> pad1.value,
         varText                |-> varText.value,
         alignmentPadding       |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroReject ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp12,
      sessionRejectReason    |-> [i \in 1 .. 4 |-> 0],
      sessionStatus          |-> [i \in 1 .. 1 |-> 0],
      pad1                   |-> [i \in 1 .. 1 |-> 0],
      varText                |-> << >>,
      alignmentPadding       |-> << >> ]

(* Reject at zero, then each field in turn at the values it is checked at *)
CheckedReject ==
    { ZeroReject }
        \cup { [ZeroReject EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroReject EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp12 }
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
    [ pad2                  : Sample(2),
      responseHeaderComp    : ResponseHeaderComp6,
      applTotalMessageCount : Sample(2),
      applEndMsgId          : Sample(16),
      refApplLastMsgId      : Sample(16),
      pad6                  : Sample(6) ]

EncodeRetransmitMeMessageResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp6(message.responseHeaderComp)
        \o message.applTotalMessageCount
        \o message.applEndMsgId
        \o message.refApplLastMsgId
        \o message.pad6

DecodeRetransmitMeMessageResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp6(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET applTotalMessageCount == ReadBytes(responseHeaderComp.rest, 2) IN IF ~applTotalMessageCount.ok THEN Fail ELSE
    LET applEndMsgId == ReadBytes(applTotalMessageCount.rest, 16) IN IF ~applEndMsgId.ok THEN Fail ELSE
    LET refApplLastMsgId == ReadBytes(applEndMsgId.rest, 16) IN IF ~refApplLastMsgId.ok THEN Fail ELSE
    LET pad6 == ReadBytes(refApplLastMsgId.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         responseHeaderComp    |-> responseHeaderComp.value,
         applTotalMessageCount |-> applTotalMessageCount.value,
         applEndMsgId          |-> applEndMsgId.value,
         refApplLastMsgId      |-> refApplLastMsgId.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroRetransmitMeMessageResponse ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp    |-> ZeroResponseHeaderComp6,
      applTotalMessageCount |-> [i \in 1 .. 2 |-> 0],
      applEndMsgId          |-> [i \in 1 .. 16 |-> 0],
      refApplLastMsgId      |-> [i \in 1 .. 16 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Retransmit Me Message Response at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitMeMessageResponse ==
    { ZeroRetransmitMeMessageResponse }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
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
    [ pad2                  : Sample(2),
      responseHeaderComp    : ResponseHeaderComp7,
      applEndSeqNum         : Sample(8),
      refApplLastSeqNum     : Sample(8),
      applTotalMessageCount : Sample(2),
      pad6                  : Sample(6) ]

EncodeRetransmitResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp7(message.responseHeaderComp)
        \o message.applEndSeqNum
        \o message.refApplLastSeqNum
        \o message.applTotalMessageCount
        \o message.pad6

DecodeRetransmitResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp7(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET applEndSeqNum == ReadBytes(responseHeaderComp.rest, 8) IN IF ~applEndSeqNum.ok THEN Fail ELSE
    LET refApplLastSeqNum == ReadBytes(applEndSeqNum.rest, 8) IN IF ~refApplLastSeqNum.ok THEN Fail ELSE
    LET applTotalMessageCount == ReadBytes(refApplLastSeqNum.rest, 2) IN IF ~applTotalMessageCount.ok THEN Fail ELSE
    LET pad6 == ReadBytes(applTotalMessageCount.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         responseHeaderComp    |-> responseHeaderComp.value,
         applEndSeqNum         |-> applEndSeqNum.value,
         refApplLastSeqNum     |-> refApplLastSeqNum.value,
         applTotalMessageCount |-> applTotalMessageCount.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroRetransmitResponse ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp    |-> ZeroResponseHeaderComp7,
      applEndSeqNum         |-> [i \in 1 .. 8 |-> 0],
      refApplLastSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applTotalMessageCount |-> [i \in 1 .. 2 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Retransmit Response at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitResponse ==
    { ZeroRetransmitResponse }
        \cup { [ZeroRetransmitResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp7 }
        \cup { [ZeroRetransmitResponse EXCEPT !.applEndSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitResponse EXCEPT !.refApplLastSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitResponse EXCEPT !.applTotalMessageCount = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Service Availability Broadcast: 50 bytes                                *)
(***************************************************************************)

ServiceAvailabilityBroadcast ==
    [ pad2                       : Sample(2),
      nrbcHeaderComp             : NrbcHeaderComp,
      matchingEngineTradeDate    : Sample(4),
      tradeManagerTradeDate      : Sample(4),
      applSeqTradeDate           : Sample(4),
      t7EntryServiceTradeDate    : Sample(4),
      t7EntryServiceRtmTradeDate : Sample(4),
      partitionId                : Sample(2),
      matchingEngineStatus       : Sample(1),
      tradeManagerStatus         : Sample(1),
      applSeqStatus              : Sample(1),
      t7EntryServiceStatus       : Sample(1),
      t7EntryServiceRtmStatus    : Sample(1),
      pad5                       : Sample(5) ]

EncodeServiceAvailabilityBroadcast(message) ==
    message.pad2
        \o EncodeNrbcHeaderComp(message.nrbcHeaderComp)
        \o message.matchingEngineTradeDate
        \o message.tradeManagerTradeDate
        \o message.applSeqTradeDate
        \o message.t7EntryServiceTradeDate
        \o message.t7EntryServiceRtmTradeDate
        \o message.partitionId
        \o message.matchingEngineStatus
        \o message.tradeManagerStatus
        \o message.applSeqStatus
        \o message.t7EntryServiceStatus
        \o message.t7EntryServiceRtmStatus
        \o message.pad5

DecodeServiceAvailabilityBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrbcHeaderComp == DecodeNrbcHeaderComp(pad2.rest) IN IF ~nrbcHeaderComp.ok THEN Fail ELSE
    LET matchingEngineTradeDate == ReadBytes(nrbcHeaderComp.rest, 4) IN IF ~matchingEngineTradeDate.ok THEN Fail ELSE
    LET tradeManagerTradeDate == ReadBytes(matchingEngineTradeDate.rest, 4) IN IF ~tradeManagerTradeDate.ok THEN Fail ELSE
    LET applSeqTradeDate == ReadBytes(tradeManagerTradeDate.rest, 4) IN IF ~applSeqTradeDate.ok THEN Fail ELSE
    LET t7EntryServiceTradeDate == ReadBytes(applSeqTradeDate.rest, 4) IN IF ~t7EntryServiceTradeDate.ok THEN Fail ELSE
    LET t7EntryServiceRtmTradeDate == ReadBytes(t7EntryServiceTradeDate.rest, 4) IN IF ~t7EntryServiceRtmTradeDate.ok THEN Fail ELSE
    LET partitionId == ReadBytes(t7EntryServiceRtmTradeDate.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET matchingEngineStatus == ReadBytes(partitionId.rest, 1) IN IF ~matchingEngineStatus.ok THEN Fail ELSE
    LET tradeManagerStatus == ReadBytes(matchingEngineStatus.rest, 1) IN IF ~tradeManagerStatus.ok THEN Fail ELSE
    LET applSeqStatus == ReadBytes(tradeManagerStatus.rest, 1) IN IF ~applSeqStatus.ok THEN Fail ELSE
    LET t7EntryServiceStatus == ReadBytes(applSeqStatus.rest, 1) IN IF ~t7EntryServiceStatus.ok THEN Fail ELSE
    LET t7EntryServiceRtmStatus == ReadBytes(t7EntryServiceStatus.rest, 1) IN IF ~t7EntryServiceRtmStatus.ok THEN Fail ELSE
    LET pad5 == ReadBytes(t7EntryServiceRtmStatus.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ pad2                       |-> pad2.value,
         nrbcHeaderComp             |-> nrbcHeaderComp.value,
         matchingEngineTradeDate    |-> matchingEngineTradeDate.value,
         tradeManagerTradeDate      |-> tradeManagerTradeDate.value,
         applSeqTradeDate           |-> applSeqTradeDate.value,
         t7EntryServiceTradeDate    |-> t7EntryServiceTradeDate.value,
         t7EntryServiceRtmTradeDate |-> t7EntryServiceRtmTradeDate.value,
         partitionId                |-> partitionId.value,
         matchingEngineStatus       |-> matchingEngineStatus.value,
         tradeManagerStatus         |-> tradeManagerStatus.value,
         applSeqStatus              |-> applSeqStatus.value,
         t7EntryServiceStatus       |-> t7EntryServiceStatus.value,
         t7EntryServiceRtmStatus    |-> t7EntryServiceRtmStatus.value,
         pad5                       |-> pad5.value ], pad5.rest)

ZeroServiceAvailabilityBroadcast ==
    [ pad2                       |-> [i \in 1 .. 2 |-> 0],
      nrbcHeaderComp             |-> ZeroNrbcHeaderComp,
      matchingEngineTradeDate    |-> [i \in 1 .. 4 |-> 0],
      tradeManagerTradeDate      |-> [i \in 1 .. 4 |-> 0],
      applSeqTradeDate           |-> [i \in 1 .. 4 |-> 0],
      t7EntryServiceTradeDate    |-> [i \in 1 .. 4 |-> 0],
      t7EntryServiceRtmTradeDate |-> [i \in 1 .. 4 |-> 0],
      partitionId                |-> [i \in 1 .. 2 |-> 0],
      matchingEngineStatus       |-> [i \in 1 .. 1 |-> 0],
      tradeManagerStatus         |-> [i \in 1 .. 1 |-> 0],
      applSeqStatus              |-> [i \in 1 .. 1 |-> 0],
      t7EntryServiceStatus       |-> [i \in 1 .. 1 |-> 0],
      t7EntryServiceRtmStatus    |-> [i \in 1 .. 1 |-> 0],
      pad5                       |-> [i \in 1 .. 5 |-> 0] ]

(* Service Availability Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedServiceAvailabilityBroadcast ==
    { ZeroServiceAvailabilityBroadcast }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.nrbcHeaderComp = one] : one \in CheckedNrbcHeaderComp }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.matchingEngineTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.tradeManagerTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.applSeqTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.t7EntryServiceTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.t7EntryServiceRtmTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.matchingEngineStatus = one] : one \in Sample(1) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.tradeManagerStatus = one] : one \in Sample(1) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.applSeqStatus = one] : one \in Sample(1) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.t7EntryServiceStatus = one] : one \in Sample(1) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.t7EntryServiceRtmStatus = one] : one \in Sample(1) }
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Nrbc Header Comp: 16 bytes                                              *)
(***************************************************************************)

NrbcHeaderComp2 ==
    [ sendingTime  : Sample(8),
      applSubId    : Sample(4),
      applId       : Sample(1),
      lastFragment : Sample(1),
      pad2         : Sample(2) ]

EncodeNrbcHeaderComp2(message) ==
    message.sendingTime
        \o message.applSubId
        \o message.applId
        \o message.lastFragment
        \o message.pad2

DecodeNrbcHeaderComp2(bytes) ==
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

ZeroNrbcHeaderComp2 ==
    [ sendingTime  |-> [i \in 1 .. 8 |-> 0],
      applSubId    |-> [i \in 1 .. 4 |-> 0],
      applId       |-> [i \in 1 .. 1 |-> 0],
      lastFragment |-> [i \in 1 .. 1 |-> 0],
      pad2         |-> [i \in 1 .. 2 |-> 0] ]

(* Nrbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrbcHeaderComp2 ==
    { ZeroNrbcHeaderComp2 }
        \cup { [ZeroNrbcHeaderComp2 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrbcHeaderComp2 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroNrbcHeaderComp2 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroNrbcHeaderComp2 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrbcHeaderComp2 EXCEPT !.pad2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Service Availability Market Broadcast: 26 bytes                         *)
(***************************************************************************)

ServiceAvailabilityMarketBroadcast ==
    [ pad2                                     : Sample(2),
      nrbcHeaderComp                           : NrbcHeaderComp2,
      selectiveRequestForQuoteServiceTradeDate : Sample(4),
      selectiveRequestForQuoteServiceStatus    : Sample(1),
      pad3                                     : Sample(3) ]

EncodeServiceAvailabilityMarketBroadcast(message) ==
    message.pad2
        \o EncodeNrbcHeaderComp2(message.nrbcHeaderComp)
        \o message.selectiveRequestForQuoteServiceTradeDate
        \o message.selectiveRequestForQuoteServiceStatus
        \o message.pad3

DecodeServiceAvailabilityMarketBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrbcHeaderComp == DecodeNrbcHeaderComp2(pad2.rest) IN IF ~nrbcHeaderComp.ok THEN Fail ELSE
    LET selectiveRequestForQuoteServiceTradeDate == ReadBytes(nrbcHeaderComp.rest, 4) IN IF ~selectiveRequestForQuoteServiceTradeDate.ok THEN Fail ELSE
    LET selectiveRequestForQuoteServiceStatus == ReadBytes(selectiveRequestForQuoteServiceTradeDate.rest, 1) IN IF ~selectiveRequestForQuoteServiceStatus.ok THEN Fail ELSE
    LET pad3 == ReadBytes(selectiveRequestForQuoteServiceStatus.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2                                     |-> pad2.value,
         nrbcHeaderComp                           |-> nrbcHeaderComp.value,
         selectiveRequestForQuoteServiceTradeDate |-> selectiveRequestForQuoteServiceTradeDate.value,
         selectiveRequestForQuoteServiceStatus    |-> selectiveRequestForQuoteServiceStatus.value,
         pad3                                     |-> pad3.value ], pad3.rest)

ZeroServiceAvailabilityMarketBroadcast ==
    [ pad2                                     |-> [i \in 1 .. 2 |-> 0],
      nrbcHeaderComp                           |-> ZeroNrbcHeaderComp2,
      selectiveRequestForQuoteServiceTradeDate |-> [i \in 1 .. 4 |-> 0],
      selectiveRequestForQuoteServiceStatus    |-> [i \in 1 .. 1 |-> 0],
      pad3                                     |-> [i \in 1 .. 3 |-> 0] ]

(* Service Availability Market Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedServiceAvailabilityMarketBroadcast ==
    { ZeroServiceAvailabilityMarketBroadcast }
        \cup { [ZeroServiceAvailabilityMarketBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroServiceAvailabilityMarketBroadcast EXCEPT !.nrbcHeaderComp = one] : one \in CheckedNrbcHeaderComp2 }
        \cup { [ZeroServiceAvailabilityMarketBroadcast EXCEPT !.selectiveRequestForQuoteServiceTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroServiceAvailabilityMarketBroadcast EXCEPT !.selectiveRequestForQuoteServiceStatus = one] : one \in Sample(1) }
        \cup { [ZeroServiceAvailabilityMarketBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp15 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp15(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp15(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp15 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp15 ==
    { ZeroRbcHeaderMeComp15 }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp15 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Affected Ord Grp Comp: 16 bytes                                         *)
(***************************************************************************)

AffectedOrdGrpComp3 ==
    [ affectedOrderId     : Sample(8),
      affectedOrigClOrdId : Sample(8) ]

EncodeAffectedOrdGrpComp3(message) ==
    message.affectedOrderId
        \o message.affectedOrigClOrdId

DecodeAffectedOrdGrpComp3(bytes) ==
    LET affectedOrderId == ReadBytes(bytes, 8) IN IF ~affectedOrderId.ok THEN Fail ELSE
    LET affectedOrigClOrdId == ReadBytes(affectedOrderId.rest, 8) IN IF ~affectedOrigClOrdId.ok THEN Fail ELSE
    Ok([ affectedOrderId     |-> affectedOrderId.value,
         affectedOrigClOrdId |-> affectedOrigClOrdId.value ], affectedOrigClOrdId.rest)

ZeroAffectedOrdGrpComp3 ==
    [ affectedOrderId     |-> [i \in 1 .. 8 |-> 0],
      affectedOrigClOrdId |-> [i \in 1 .. 8 |-> 0] ]

(* Affected Ord Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedAffectedOrdGrpComp3 ==
    { ZeroAffectedOrdGrpComp3 }
        \cup { [ZeroAffectedOrdGrpComp3 EXCEPT !.affectedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroAffectedOrdGrpComp3 EXCEPT !.affectedOrigClOrdId = one] : one \in Sample(8) }

(* A run of Affected Ord Grp Comp, written one after another *)
RECURSIVE EncodeAffectedOrdGrpComp3List(_)
EncodeAffectedOrdGrpComp3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAffectedOrdGrpComp3(Head(messages)) \o EncodeAffectedOrdGrpComp3List(Tail(messages))

(* As many Affected Ord Grp Comp as the field that counts them says *)
RECURSIVE ReadAffectedOrdGrpComp3List(_, _)
ReadAffectedOrdGrpComp3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAffectedOrdGrpComp3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAffectedOrdGrpComp3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Affected Ord Grp Comp of each kind, for the lists that carry them *)
OneAffectedOrdGrpComp3 == { ZeroAffectedOrdGrpComp3 }

(***************************************************************************)
(* Not Affected Orders Grp Comp: 16 bytes                                  *)
(***************************************************************************)

NotAffectedOrdersGrpComp3 ==
    [ notAffectedOrderId : Sample(8),
      notAffOrigClOrdId  : Sample(8) ]

EncodeNotAffectedOrdersGrpComp3(message) ==
    message.notAffectedOrderId
        \o message.notAffOrigClOrdId

DecodeNotAffectedOrdersGrpComp3(bytes) ==
    LET notAffectedOrderId == ReadBytes(bytes, 8) IN IF ~notAffectedOrderId.ok THEN Fail ELSE
    LET notAffOrigClOrdId == ReadBytes(notAffectedOrderId.rest, 8) IN IF ~notAffOrigClOrdId.ok THEN Fail ELSE
    Ok([ notAffectedOrderId |-> notAffectedOrderId.value,
         notAffOrigClOrdId  |-> notAffOrigClOrdId.value ], notAffOrigClOrdId.rest)

ZeroNotAffectedOrdersGrpComp3 ==
    [ notAffectedOrderId |-> [i \in 1 .. 8 |-> 0],
      notAffOrigClOrdId  |-> [i \in 1 .. 8 |-> 0] ]

(* Not Affected Orders Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotAffectedOrdersGrpComp3 ==
    { ZeroNotAffectedOrdersGrpComp3 }
        \cup { [ZeroNotAffectedOrdersGrpComp3 EXCEPT !.notAffectedOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNotAffectedOrdersGrpComp3 EXCEPT !.notAffOrigClOrdId = one] : one \in Sample(8) }

(* A run of Not Affected Orders Grp Comp, written one after another *)
RECURSIVE EncodeNotAffectedOrdersGrpComp3List(_)
EncodeNotAffectedOrdersGrpComp3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNotAffectedOrdersGrpComp3(Head(messages)) \o EncodeNotAffectedOrdersGrpComp3List(Tail(messages))

(* As many Not Affected Orders Grp Comp as the field that counts them says *)
RECURSIVE ReadNotAffectedOrdersGrpComp3List(_, _)
ReadNotAffectedOrdersGrpComp3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNotAffectedOrdersGrpComp3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNotAffectedOrdersGrpComp3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Not Affected Orders Grp Comp of each kind, for the lists that carry them *)
OneNotAffectedOrdersGrpComp3 == { ZeroNotAffectedOrdersGrpComp3 }

(***************************************************************************)
(* Specialist Delete All Order Broadcast                                   *)
(***************************************************************************)

SpecialistDeleteAllOrderBroadcast ==
    [ pad2                     : Sample(2),
      rbcHeaderMeComp          : RbcHeaderMeComp15,
      massActionReportId       : Sample(8),
      marketSegmentId          : Sample(4),
      partyIdEnteringTrader    : Sample(4),
      partyIdEnteringFirm      : Sample(1),
      massActionReason         : Sample(1),
      pad2v2                   : Sample(2),
      affectedOrdGrpComp       : SampleLists(OneAffectedOrdGrpComp3),
      notAffectedOrdersGrpComp : SampleLists(OneNotAffectedOrdersGrpComp3) ]

EncodeSpecialistDeleteAllOrderBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp15(message.rbcHeaderMeComp)
        \o message.massActionReportId
        \o message.marketSegmentId
        \o message.partyIdEnteringTrader
        \o EncodeUIntLE(Len(message.affectedOrdGrpComp), 2)
        \o EncodeUIntLE(Len(message.notAffectedOrdersGrpComp), 2)
        \o message.partyIdEnteringFirm
        \o message.massActionReason
        \o message.pad2v2
        \o EncodeAffectedOrdGrpComp3List(message.affectedOrdGrpComp)
        \o EncodeNotAffectedOrdersGrpComp3List(message.notAffectedOrdersGrpComp)

DecodeSpecialistDeleteAllOrderBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp15(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(massActionReportId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(marketSegmentId.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET noAffectedOrders == ReadUIntLE(partyIdEnteringTrader.rest, 2) IN IF ~noAffectedOrders.ok THEN Fail ELSE
    LET noNotAffectedOrders == ReadUIntLE(noAffectedOrders.rest, 2) IN IF ~noNotAffectedOrders.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(noNotAffectedOrders.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET massActionReason == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~massActionReason.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(massActionReason.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET affectedOrdGrpComp == ReadAffectedOrdGrpComp3List(pad2v2.rest, noAffectedOrders.value) IN IF ~affectedOrdGrpComp.ok THEN Fail ELSE
    LET notAffectedOrdersGrpComp == ReadNotAffectedOrdersGrpComp3List(affectedOrdGrpComp.rest, noNotAffectedOrders.value) IN IF ~notAffectedOrdersGrpComp.ok THEN Fail ELSE
    Ok([ pad2                     |-> pad2.value,
         rbcHeaderMeComp          |-> rbcHeaderMeComp.value,
         massActionReportId       |-> massActionReportId.value,
         marketSegmentId          |-> marketSegmentId.value,
         partyIdEnteringTrader    |-> partyIdEnteringTrader.value,
         partyIdEnteringFirm      |-> partyIdEnteringFirm.value,
         massActionReason         |-> massActionReason.value,
         pad2v2                   |-> pad2v2.value,
         affectedOrdGrpComp       |-> affectedOrdGrpComp.value,
         notAffectedOrdersGrpComp |-> notAffectedOrdersGrpComp.value ], notAffectedOrdersGrpComp.rest)

ZeroSpecialistDeleteAllOrderBroadcast ==
    [ pad2                     |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp          |-> ZeroRbcHeaderMeComp15,
      massActionReportId       |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId          |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader    |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringFirm      |-> [i \in 1 .. 1 |-> 0],
      massActionReason         |-> [i \in 1 .. 1 |-> 0],
      pad2v2                   |-> [i \in 1 .. 2 |-> 0],
      affectedOrdGrpComp       |-> << >>,
      notAffectedOrdersGrpComp |-> << >> ]

(* Specialist Delete All Order Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedSpecialistDeleteAllOrderBroadcast ==
    { ZeroSpecialistDeleteAllOrderBroadcast }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp15 }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.massActionReason = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.affectedOrdGrpComp = one] : one \in SampleLists(OneAffectedOrdGrpComp3) }
        \cup { [ZeroSpecialistDeleteAllOrderBroadcast EXCEPT !.notAffectedOrdersGrpComp = one] : one \in SampleLists(OneNotAffectedOrdersGrpComp3) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp16 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp16(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp16(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp16 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp16 ==
    { ZeroRbcHeaderMeComp16 }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp16 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Specialist Instrument Event Notification: 82 bytes                      *)
(***************************************************************************)

SpecialistInstrumentEventNotification ==
    [ pad2            : Sample(2),
      rbcHeaderMeComp : RbcHeaderMeComp16,
      securityId      : Sample(8),
      transactTime    : Sample(8),
      marketSegmentId : Sample(4),
      eventType       : Sample(1),
      pad3            : Sample(3) ]

EncodeSpecialistInstrumentEventNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp16(message.rbcHeaderMeComp)
        \o message.securityId
        \o message.transactTime
        \o message.marketSegmentId
        \o message.eventType
        \o message.pad3

DecodeSpecialistInstrumentEventNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp16(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(transactTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET eventType == ReadBytes(marketSegmentId.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET pad3 == ReadBytes(eventType.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2            |-> pad2.value,
         rbcHeaderMeComp |-> rbcHeaderMeComp.value,
         securityId      |-> securityId.value,
         transactTime    |-> transactTime.value,
         marketSegmentId |-> marketSegmentId.value,
         eventType       |-> eventType.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroSpecialistInstrumentEventNotification ==
    [ pad2            |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp |-> ZeroRbcHeaderMeComp16,
      securityId      |-> [i \in 1 .. 8 |-> 0],
      transactTime    |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId |-> [i \in 1 .. 4 |-> 0],
      eventType       |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Specialist Instrument Event Notification at zero, then each field in turn at the values it is checked at *)
CheckedSpecialistInstrumentEventNotification ==
    { ZeroSpecialistInstrumentEventNotification }
        \cup { [ZeroSpecialistInstrumentEventNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistInstrumentEventNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp16 }
        \cup { [ZeroSpecialistInstrumentEventNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistInstrumentEventNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistInstrumentEventNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistInstrumentEventNotification EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistInstrumentEventNotification EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp17 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp17(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp17(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp17 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp17 ==
    { ZeroRbcHeaderMeComp17 }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp17 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Fills Grp Comp: 32 bytes                                                *)
(***************************************************************************)

FillsGrpComp4 ==
    [ fillPx           : Sample(8),
      fillQty          : Sample(8),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad7             : Sample(7) ]

EncodeFillsGrpComp4(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad7

DecodeFillsGrpComp4(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 8) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad7 == ReadBytes(fillLiquidityInd.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroFillsGrpComp4 ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 8 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp4 ==
    { ZeroFillsGrpComp4 }
        \cup { [ZeroFillsGrpComp4 EXCEPT !.fillPx = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp4 EXCEPT !.fillQty = one] : one \in Sample(8) }
        \cup { [ZeroFillsGrpComp4 EXCEPT !.fillMatchId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp4 EXCEPT !.fillExecId = one] : one \in Sample(4) }
        \cup { [ZeroFillsGrpComp4 EXCEPT !.fillLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroFillsGrpComp4 EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Fills Grp Comp, written one after another *)
RECURSIVE EncodeFillsGrpComp4List(_)
EncodeFillsGrpComp4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillsGrpComp4(Head(messages)) \o EncodeFillsGrpComp4List(Tail(messages))

(* As many Fills Grp Comp as the field that counts them says *)
RECURSIVE ReadFillsGrpComp4List(_, _)
ReadFillsGrpComp4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillsGrpComp4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillsGrpComp4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fills Grp Comp of each kind, for the lists that carry them *)
OneFillsGrpComp4 == { ZeroFillsGrpComp4 }

(***************************************************************************)
(* Specialist Order Book Notification                                      *)
(***************************************************************************)

SpecialistOrderBookNotification ==
    [ pad2                             : Sample(2),
      rbcHeaderMeComp                  : RbcHeaderMeComp17,
      orderId                          : Sample(8),
      clOrdId                          : Sample(8),
      origClOrdId                      : Sample(8),
      securityId                       : Sample(8),
      execId                           : Sample(8),
      trdRegTsEntryTime                : Sample(8),
      trdRegTsTimePriority             : Sample(8),
      price                            : Sample(8),
      leavesQty                        : Sample(8),
      cumQty                           : Sample(8),
      cxlQty                           : Sample(8),
      orderQty                         : Sample(8),
      stopPx                           : Sample(8),
      quoteId                          : Sample(8),
      marketSegmentId                  : Sample(4),
      orderIdSfx                       : Sample(4),
      expireDate                       : Sample(4),
      partyIdExecutingUnit             : Sample(4),
      partyIdSessionId                 : Sample(4),
      partyIdExecutingTrader           : Sample(4),
      partyIdEnteringTrader            : Sample(4),
      pad1                             : Sample(1),
      execRestatementReason            : Sample(2),
      partyIdEnteringFirm              : Sample(1),
      ordStatus                        : Sample(1),
      execType                         : Sample(1),
      orderEventType                   : Sample(1),
      matchType                        : Sample(1),
      side                             : Sample(1),
      ordType                          : Sample(1),
      tradingCapacity                  : Sample(1),
      timeInForce                      : Sample(1),
      execInst                         : Sample(1),
      tradingSessionSubId              : Sample(1),
      applSeqIndicator                 : Sample(1),
      triggered                        : Sample(1),
      orderAttributeLiquidityProvision : Sample(1),
      partyEnteringFirm                : Sample(5),
      partyEnteringTrader              : Sample(6),
      partyExecutingFirm               : Sample(5),
      partyExecutingTrader             : Sample(6),
      fixClOrdId                       : Sample(20),
      fillsGrpComp                     : SampleLists(OneFillsGrpComp4) ]

EncodeSpecialistOrderBookNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp17(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.trdRegTsEntryTime
        \o message.trdRegTsTimePriority
        \o message.price
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.orderQty
        \o message.stopPx
        \o message.quoteId
        \o message.marketSegmentId
        \o message.orderIdSfx
        \o message.expireDate
        \o message.partyIdExecutingUnit
        \o message.partyIdSessionId
        \o message.partyIdExecutingTrader
        \o message.partyIdEnteringTrader
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.pad1
        \o message.execRestatementReason
        \o message.partyIdEnteringFirm
        \o message.ordStatus
        \o message.execType
        \o message.orderEventType
        \o message.matchType
        \o message.side
        \o message.ordType
        \o message.tradingCapacity
        \o message.timeInForce
        \o message.execInst
        \o message.tradingSessionSubId
        \o message.applSeqIndicator
        \o message.triggered
        \o message.orderAttributeLiquidityProvision
        \o message.partyEnteringFirm
        \o message.partyEnteringTrader
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.fixClOrdId
        \o EncodeFillsGrpComp4List(message.fillsGrpComp)

DecodeSpecialistOrderBookNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp17(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET trdRegTsEntryTime == ReadBytes(execId.rest, 8) IN IF ~trdRegTsEntryTime.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(trdRegTsEntryTime.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET price == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(price.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 8) IN IF ~cxlQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(cxlQty.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET stopPx == ReadBytes(orderQty.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET quoteId == ReadBytes(stopPx.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET expireDate == ReadBytes(orderIdSfx.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(expireDate.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(partyIdExecutingUnit.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET partyIdExecutingTrader == ReadBytes(partyIdSessionId.rest, 4) IN IF ~partyIdExecutingTrader.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(partyIdExecutingTrader.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(partyIdEnteringTrader.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET pad1 == ReadBytes(noFills.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(pad1.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(execRestatementReason.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET orderEventType == ReadBytes(execType.rest, 1) IN IF ~orderEventType.ok THEN Fail ELSE
    LET matchType == ReadBytes(orderEventType.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET side == ReadBytes(matchType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(ordType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(tradingCapacity.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(execInst.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET triggered == ReadBytes(applSeqIndicator.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(triggered.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET partyEnteringFirm == ReadBytes(orderAttributeLiquidityProvision.rest, 5) IN IF ~partyEnteringFirm.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyEnteringFirm.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(partyEnteringTrader.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(partyExecutingTrader.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpComp4List(fixClOrdId.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                             |-> pad2.value,
         rbcHeaderMeComp                  |-> rbcHeaderMeComp.value,
         orderId                          |-> orderId.value,
         clOrdId                          |-> clOrdId.value,
         origClOrdId                      |-> origClOrdId.value,
         securityId                       |-> securityId.value,
         execId                           |-> execId.value,
         trdRegTsEntryTime                |-> trdRegTsEntryTime.value,
         trdRegTsTimePriority             |-> trdRegTsTimePriority.value,
         price                            |-> price.value,
         leavesQty                        |-> leavesQty.value,
         cumQty                           |-> cumQty.value,
         cxlQty                           |-> cxlQty.value,
         orderQty                         |-> orderQty.value,
         stopPx                           |-> stopPx.value,
         quoteId                          |-> quoteId.value,
         marketSegmentId                  |-> marketSegmentId.value,
         orderIdSfx                       |-> orderIdSfx.value,
         expireDate                       |-> expireDate.value,
         partyIdExecutingUnit             |-> partyIdExecutingUnit.value,
         partyIdSessionId                 |-> partyIdSessionId.value,
         partyIdExecutingTrader           |-> partyIdExecutingTrader.value,
         partyIdEnteringTrader            |-> partyIdEnteringTrader.value,
         pad1                             |-> pad1.value,
         execRestatementReason            |-> execRestatementReason.value,
         partyIdEnteringFirm              |-> partyIdEnteringFirm.value,
         ordStatus                        |-> ordStatus.value,
         execType                         |-> execType.value,
         orderEventType                   |-> orderEventType.value,
         matchType                        |-> matchType.value,
         side                             |-> side.value,
         ordType                          |-> ordType.value,
         tradingCapacity                  |-> tradingCapacity.value,
         timeInForce                      |-> timeInForce.value,
         execInst                         |-> execInst.value,
         tradingSessionSubId              |-> tradingSessionSubId.value,
         applSeqIndicator                 |-> applSeqIndicator.value,
         triggered                        |-> triggered.value,
         orderAttributeLiquidityProvision |-> orderAttributeLiquidityProvision.value,
         partyEnteringFirm                |-> partyEnteringFirm.value,
         partyEnteringTrader              |-> partyEnteringTrader.value,
         partyExecutingFirm               |-> partyExecutingFirm.value,
         partyExecutingTrader             |-> partyExecutingTrader.value,
         fixClOrdId                       |-> fixClOrdId.value,
         fillsGrpComp                     |-> fillsGrpComp.value ], fillsGrpComp.rest)

ZeroSpecialistOrderBookNotification ==
    [ pad2                             |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp                  |-> ZeroRbcHeaderMeComp17,
      orderId                          |-> [i \in 1 .. 8 |-> 0],
      clOrdId                          |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                      |-> [i \in 1 .. 8 |-> 0],
      securityId                       |-> [i \in 1 .. 8 |-> 0],
      execId                           |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority             |-> [i \in 1 .. 8 |-> 0],
      price                            |-> [i \in 1 .. 8 |-> 0],
      leavesQty                        |-> [i \in 1 .. 8 |-> 0],
      cumQty                           |-> [i \in 1 .. 8 |-> 0],
      cxlQty                           |-> [i \in 1 .. 8 |-> 0],
      orderQty                         |-> [i \in 1 .. 8 |-> 0],
      stopPx                           |-> [i \in 1 .. 8 |-> 0],
      quoteId                          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                  |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx                       |-> [i \in 1 .. 4 |-> 0],
      expireDate                       |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingUnit             |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId                 |-> [i \in 1 .. 4 |-> 0],
      partyIdExecutingTrader           |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader            |-> [i \in 1 .. 4 |-> 0],
      pad1                             |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason            |-> [i \in 1 .. 2 |-> 0],
      partyIdEnteringFirm              |-> [i \in 1 .. 1 |-> 0],
      ordStatus                        |-> [i \in 1 .. 1 |-> 0],
      execType                         |-> [i \in 1 .. 1 |-> 0],
      orderEventType                   |-> [i \in 1 .. 1 |-> 0],
      matchType                        |-> [i \in 1 .. 1 |-> 0],
      side                             |-> [i \in 1 .. 1 |-> 0],
      ordType                          |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                  |-> [i \in 1 .. 1 |-> 0],
      timeInForce                      |-> [i \in 1 .. 1 |-> 0],
      execInst                         |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId              |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator                 |-> [i \in 1 .. 1 |-> 0],
      triggered                        |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision |-> [i \in 1 .. 1 |-> 0],
      partyEnteringFirm                |-> [i \in 1 .. 5 |-> 0],
      partyEnteringTrader              |-> [i \in 1 .. 6 |-> 0],
      partyExecutingFirm               |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader             |-> [i \in 1 .. 6 |-> 0],
      fixClOrdId                       |-> [i \in 1 .. 20 |-> 0],
      fillsGrpComp                     |-> << >> ]

(* Specialist Order Book Notification at zero, then each field in turn at the values it is checked at *)
CheckedSpecialistOrderBookNotification ==
    { ZeroSpecialistOrderBookNotification }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp17 }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.trdRegTsEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.cxlQty = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.partyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.partyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.orderEventType = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.partyEnteringFirm = one] : one \in Sample(5) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroSpecialistOrderBookNotification EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp4) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp18 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp18(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp18(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp18 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp18 ==
    { ZeroRbcHeaderMeComp18 }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp18 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Specialist Rfq Reply Notification: 130 bytes                            *)
(***************************************************************************)

SpecialistRfqReplyNotification ==
    [ pad2               : Sample(2),
      rbcHeaderMeComp    : RbcHeaderMeComp18,
      securityId         : Sample(8),
      transactTime       : Sample(8),
      quoteId            : Sample(8),
      bidPx              : Sample(8),
      bidSize            : Sample(8),
      offerPx            : Sample(8),
      offerSize          : Sample(8),
      marketSegmentId    : Sample(4),
      partyExecutingFirm : Sample(5),
      pad7               : Sample(7) ]

EncodeSpecialistRfqReplyNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp18(message.rbcHeaderMeComp)
        \o message.securityId
        \o message.transactTime
        \o message.quoteId
        \o message.bidPx
        \o message.bidSize
        \o message.offerPx
        \o message.offerSize
        \o message.marketSegmentId
        \o message.partyExecutingFirm
        \o message.pad7

DecodeSpecialistRfqReplyNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp18(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET quoteId == ReadBytes(transactTime.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(quoteId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidSize.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPx.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(offerSize.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(marketSegmentId.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET pad7 == ReadBytes(partyExecutingFirm.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         rbcHeaderMeComp    |-> rbcHeaderMeComp.value,
         securityId         |-> securityId.value,
         transactTime       |-> transactTime.value,
         quoteId            |-> quoteId.value,
         bidPx              |-> bidPx.value,
         bidSize            |-> bidSize.value,
         offerPx            |-> offerPx.value,
         offerSize          |-> offerSize.value,
         marketSegmentId    |-> marketSegmentId.value,
         partyExecutingFirm |-> partyExecutingFirm.value,
         pad7               |-> pad7.value ], pad7.rest)

ZeroSpecialistRfqReplyNotification ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp    |-> ZeroRbcHeaderMeComp18,
      securityId         |-> [i \in 1 .. 8 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0],
      quoteId            |-> [i \in 1 .. 8 |-> 0],
      bidPx              |-> [i \in 1 .. 8 |-> 0],
      bidSize            |-> [i \in 1 .. 8 |-> 0],
      offerPx            |-> [i \in 1 .. 8 |-> 0],
      offerSize          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      partyExecutingFirm |-> [i \in 1 .. 5 |-> 0],
      pad7               |-> [i \in 1 .. 7 |-> 0] ]

(* Specialist Rfq Reply Notification at zero, then each field in turn at the values it is checked at *)
CheckedSpecialistRfqReplyNotification ==
    { ZeroSpecialistRfqReplyNotification }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp18 }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSpecialistRfqReplyNotification EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp13 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp13(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp13(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp13 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp13 ==
    { ZeroNrResponseHeaderMeComp13 }
        \cup { [ZeroNrResponseHeaderMeComp13 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp13 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp13 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp13 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp13 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp13 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp13 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp13 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Specialist Rfq Reply Response: 58 bytes                                 *)
(***************************************************************************)

SpecialistRfqReplyResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp13,
      transactTime           : Sample(8) ]

EncodeSpecialistRfqReplyResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp13(message.nrResponseHeaderMeComp)
        \o message.transactTime

DecodeSpecialistRfqReplyResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp13(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         transactTime           |-> transactTime.value ], transactTime.rest)

ZeroSpecialistRfqReplyResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp13,
      transactTime           |-> [i \in 1 .. 8 |-> 0] ]

(* Specialist Rfq Reply Response at zero, then each field in turn at the values it is checked at *)
CheckedSpecialistRfqReplyResponse ==
    { ZeroSpecialistRfqReplyResponse }
        \cup { [ZeroSpecialistRfqReplyResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistRfqReplyResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp13 }
        \cup { [ZeroSpecialistRfqReplyResponse EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Nr Response Header Me Comp: 48 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp14 ==
    [ requestTime     : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp14(message) ==
    message.requestTime
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp14(bytes) ==
    LET requestTime == ReadBytes(bytes, 8) IN IF ~requestTime.ok THEN Fail ELSE
    LET trdRegTsTimeIn == ReadBytes(requestTime.rest, 8) IN IF ~trdRegTsTimeIn.ok THEN Fail ELSE
    LET trdRegTsTimeOut == ReadBytes(trdRegTsTimeIn.rest, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET responseIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~responseIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(responseIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(sendingTime.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(msgSeqNum.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad3 == ReadBytes(lastFragment.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ requestTime     |-> requestTime.value,
         trdRegTsTimeIn  |-> trdRegTsTimeIn.value,
         trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         responseIn      |-> responseIn.value,
         sendingTime     |-> sendingTime.value,
         msgSeqNum       |-> msgSeqNum.value,
         lastFragment    |-> lastFragment.value,
         pad3            |-> pad3.value ], pad3.rest)

ZeroNrResponseHeaderMeComp14 ==
    [ requestTime     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeIn  |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      responseIn      |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad3            |-> [i \in 1 .. 3 |-> 0] ]

(* Nr Response Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedNrResponseHeaderMeComp14 ==
    { ZeroNrResponseHeaderMeComp14 }
        \cup { [ZeroNrResponseHeaderMeComp14 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp14 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp14 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp14 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp14 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp14 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp14 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp14 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Specialist Security State Change Response: 58 bytes                     *)
(***************************************************************************)

SpecialistSecurityStateChangeResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp14,
      securityStatusReportId : Sample(8) ]

EncodeSpecialistSecurityStateChangeResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp14(message.nrResponseHeaderMeComp)
        \o message.securityStatusReportId

DecodeSpecialistSecurityStateChangeResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp14(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET securityStatusReportId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~securityStatusReportId.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         securityStatusReportId |-> securityStatusReportId.value ], securityStatusReportId.rest)

ZeroSpecialistSecurityStateChangeResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp14,
      securityStatusReportId |-> [i \in 1 .. 8 |-> 0] ]

(* Specialist Security State Change Response at zero, then each field in turn at the values it is checked at *)
CheckedSpecialistSecurityStateChangeResponse ==
    { ZeroSpecialistSecurityStateChangeResponse }
        \cup { [ZeroSpecialistSecurityStateChangeResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistSecurityStateChangeResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp14 }
        \cup { [ZeroSpecialistSecurityStateChangeResponse EXCEPT !.securityStatusReportId = one] : one \in Sample(8) }

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
(* Subscribe Response: 34 bytes                                            *)
(***************************************************************************)

SubscribeResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp8,
      applSubId          : Sample(4),
      pad4               : Sample(4) ]

EncodeSubscribeResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp8(message.responseHeaderComp)
        \o message.applSubId
        \o message.pad4

DecodeSubscribeResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp8(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET applSubId == ReadBytes(responseHeaderComp.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(applSubId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value,
         applSubId          |-> applSubId.value,
         pad4               |-> pad4.value ], pad4.rest)

ZeroSubscribeResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp8,
      applSubId          |-> [i \in 1 .. 4 |-> 0],
      pad4               |-> [i \in 1 .. 4 |-> 0] ]

(* Subscribe Response at zero, then each field in turn at the values it is checked at *)
CheckedSubscribeResponse ==
    { ZeroSubscribeResponse }
        \cup { [ZeroSubscribeResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSubscribeResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp8 }
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
(* Tes Approve Broadcast                                                   *)
(***************************************************************************)

TesApproveBroadcast ==
    [ pad2                     : Sample(2),
      rbcHeaderComp            : RbcHeaderComp5,
      securityId               : Sample(8),
      lastPx                   : Sample(8),
      allocQty                 : Sample(8),
      transactTime             : Sample(8),
      transBkdTime             : Sample(8),
      settlCurrFxRate          : Sample(8),
      marketSegmentId          : Sample(4),
      packageId                : Sample(4),
      tesExecId                : Sample(4),
      allocId                  : Sample(4),
      settlDate                : Sample(4),
      tesEnrichmentRuleId      : Sample(4),
      autoApprovalRuleId       : Sample(4),
      trdType                  : Sample(2),
      side                     : Sample(1),
      valueCheckTypeValue      : Sample(1),
      valueCheckTypeQuantity   : Sample(1),
      tradeReportType          : Sample(1),
      tradingCapacity          : Sample(1),
      tradeAllocStatus         : Sample(1),
      messageEventSource       : Sample(1),
      tradeReportId            : Sample(20),
      partyExecutingFirm       : Sample(5),
      partyExecutingTrader     : Sample(6),
      partyIdEnteringFirm      : Sample(1),
      partyEnteringTrader      : Sample(6),
      rootPartyExecutingFirm   : Sample(5),
      rootPartyExecutingTrader : Sample(6),
      freeText1                : Sample(12),
      freeText2                : Sample(12),
      freeText4                : Sample(16),
      varText                  : SampleBytes,
      alignmentPadding         : SampleBytes ]

EncodeTesApproveBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp5(message.rbcHeaderComp)
        \o message.securityId
        \o message.lastPx
        \o message.allocQty
        \o message.transactTime
        \o message.transBkdTime
        \o message.settlCurrFxRate
        \o message.marketSegmentId
        \o message.packageId
        \o message.tesExecId
        \o message.allocId
        \o message.settlDate
        \o message.tesEnrichmentRuleId
        \o message.autoApprovalRuleId
        \o message.trdType
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.side
        \o message.valueCheckTypeValue
        \o message.valueCheckTypeQuantity
        \o message.tradeReportType
        \o message.tradingCapacity
        \o message.tradeAllocStatus
        \o message.messageEventSource
        \o message.tradeReportId
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.partyIdEnteringFirm
        \o message.partyEnteringTrader
        \o message.rootPartyExecutingFirm
        \o message.rootPartyExecutingTrader
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.varText
        \o message.alignmentPadding

DecodeTesApproveBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp5(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET allocQty == ReadBytes(lastPx.rest, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET transactTime == ReadBytes(allocQty.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(transactTime.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET settlCurrFxRate == ReadBytes(transBkdTime.rest, 8) IN IF ~settlCurrFxRate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(settlCurrFxRate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET packageId == ReadBytes(marketSegmentId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(packageId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET allocId == ReadBytes(tesExecId.rest, 4) IN IF ~allocId.ok THEN Fail ELSE
    LET settlDate == ReadBytes(allocId.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET tesEnrichmentRuleId == ReadBytes(settlDate.rest, 4) IN IF ~tesEnrichmentRuleId.ok THEN Fail ELSE
    LET autoApprovalRuleId == ReadBytes(tesEnrichmentRuleId.rest, 4) IN IF ~autoApprovalRuleId.ok THEN Fail ELSE
    LET trdType == ReadBytes(autoApprovalRuleId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(trdType.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET side == ReadBytes(varTextLen.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(side.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(tradeReportType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET tradeAllocStatus == ReadBytes(tradingCapacity.rest, 1) IN IF ~tradeAllocStatus.ok THEN Fail ELSE
    LET messageEventSource == ReadBytes(tradeAllocStatus.rest, 1) IN IF ~messageEventSource.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(messageEventSource.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(tradeReportId.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(partyExecutingTrader.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyIdEnteringFirm.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET rootPartyExecutingFirm == ReadBytes(partyEnteringTrader.rest, 5) IN IF ~rootPartyExecutingFirm.ok THEN Fail ELSE
    LET rootPartyExecutingTrader == ReadBytes(rootPartyExecutingFirm.rest, 6) IN IF ~rootPartyExecutingTrader.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(rootPartyExecutingTrader.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET varText == ReadBytes(freeText4.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2                     |-> pad2.value,
         rbcHeaderComp            |-> rbcHeaderComp.value,
         securityId               |-> securityId.value,
         lastPx                   |-> lastPx.value,
         allocQty                 |-> allocQty.value,
         transactTime             |-> transactTime.value,
         transBkdTime             |-> transBkdTime.value,
         settlCurrFxRate          |-> settlCurrFxRate.value,
         marketSegmentId          |-> marketSegmentId.value,
         packageId                |-> packageId.value,
         tesExecId                |-> tesExecId.value,
         allocId                  |-> allocId.value,
         settlDate                |-> settlDate.value,
         tesEnrichmentRuleId      |-> tesEnrichmentRuleId.value,
         autoApprovalRuleId       |-> autoApprovalRuleId.value,
         trdType                  |-> trdType.value,
         side                     |-> side.value,
         valueCheckTypeValue      |-> valueCheckTypeValue.value,
         valueCheckTypeQuantity   |-> valueCheckTypeQuantity.value,
         tradeReportType          |-> tradeReportType.value,
         tradingCapacity          |-> tradingCapacity.value,
         tradeAllocStatus         |-> tradeAllocStatus.value,
         messageEventSource       |-> messageEventSource.value,
         tradeReportId            |-> tradeReportId.value,
         partyExecutingFirm       |-> partyExecutingFirm.value,
         partyExecutingTrader     |-> partyExecutingTrader.value,
         partyIdEnteringFirm      |-> partyIdEnteringFirm.value,
         partyEnteringTrader      |-> partyEnteringTrader.value,
         rootPartyExecutingFirm   |-> rootPartyExecutingFirm.value,
         rootPartyExecutingTrader |-> rootPartyExecutingTrader.value,
         freeText1                |-> freeText1.value,
         freeText2                |-> freeText2.value,
         freeText4                |-> freeText4.value,
         varText                  |-> varText.value,
         alignmentPadding         |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroTesApproveBroadcast ==
    [ pad2                     |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp            |-> ZeroRbcHeaderComp5,
      securityId               |-> [i \in 1 .. 8 |-> 0],
      lastPx                   |-> [i \in 1 .. 8 |-> 0],
      allocQty                 |-> [i \in 1 .. 8 |-> 0],
      transactTime             |-> [i \in 1 .. 8 |-> 0],
      transBkdTime             |-> [i \in 1 .. 8 |-> 0],
      settlCurrFxRate          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId          |-> [i \in 1 .. 4 |-> 0],
      packageId                |-> [i \in 1 .. 4 |-> 0],
      tesExecId                |-> [i \in 1 .. 4 |-> 0],
      allocId                  |-> [i \in 1 .. 4 |-> 0],
      settlDate                |-> [i \in 1 .. 4 |-> 0],
      tesEnrichmentRuleId      |-> [i \in 1 .. 4 |-> 0],
      autoApprovalRuleId       |-> [i \in 1 .. 4 |-> 0],
      trdType                  |-> [i \in 1 .. 2 |-> 0],
      side                     |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue      |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity   |-> [i \in 1 .. 1 |-> 0],
      tradeReportType          |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity          |-> [i \in 1 .. 1 |-> 0],
      tradeAllocStatus         |-> [i \in 1 .. 1 |-> 0],
      messageEventSource       |-> [i \in 1 .. 1 |-> 0],
      tradeReportId            |-> [i \in 1 .. 20 |-> 0],
      partyExecutingFirm       |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader     |-> [i \in 1 .. 6 |-> 0],
      partyIdEnteringFirm      |-> [i \in 1 .. 1 |-> 0],
      partyEnteringTrader      |-> [i \in 1 .. 6 |-> 0],
      rootPartyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      freeText1                |-> [i \in 1 .. 12 |-> 0],
      freeText2                |-> [i \in 1 .. 12 |-> 0],
      freeText4                |-> [i \in 1 .. 16 |-> 0],
      varText                  |-> << >>,
      alignmentPadding         |-> << >> ]

(* Tes Approve Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTesApproveBroadcast ==
    { ZeroTesApproveBroadcast }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp5 }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.settlCurrFxRate = one] : one \in Sample(8) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.allocId = one] : one \in Sample(4) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.tesEnrichmentRuleId = one] : one \in Sample(4) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.autoApprovalRuleId = one] : one \in Sample(4) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.tradeAllocStatus = one] : one \in Sample(1) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.messageEventSource = one] : one \in Sample(1) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.rootPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.rootPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroTesApproveBroadcast EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

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
(* Side Alloc Grp Bc Comp: 32 bytes                                        *)
(***************************************************************************)

SideAllocGrpBcComp ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      tesEnrichmentRuleId  : Sample(4),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      side                 : Sample(1),
      tradeAllocStatus     : Sample(1),
      pad3                 : Sample(3) ]

EncodeSideAllocGrpBcComp(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.tesEnrichmentRuleId
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.side
        \o message.tradeAllocStatus
        \o message.pad3

DecodeSideAllocGrpBcComp(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET tesEnrichmentRuleId == ReadBytes(individualAllocId.rest, 4) IN IF ~tesEnrichmentRuleId.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(tesEnrichmentRuleId.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET side == ReadBytes(partyExecutingTrader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET tradeAllocStatus == ReadBytes(side.rest, 1) IN IF ~tradeAllocStatus.ok THEN Fail ELSE
    LET pad3 == ReadBytes(tradeAllocStatus.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         tesEnrichmentRuleId  |-> tesEnrichmentRuleId.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         side                 |-> side.value,
         tradeAllocStatus     |-> tradeAllocStatus.value,
         pad3                 |-> pad3.value ], pad3.rest)

ZeroSideAllocGrpBcComp ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      tesEnrichmentRuleId  |-> [i \in 1 .. 4 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      tradeAllocStatus     |-> [i \in 1 .. 1 |-> 0],
      pad3                 |-> [i \in 1 .. 3 |-> 0] ]

(* Side Alloc Grp Bc Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideAllocGrpBcComp ==
    { ZeroSideAllocGrpBcComp }
        \cup { [ZeroSideAllocGrpBcComp EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocGrpBcComp EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpBcComp EXCEPT !.tesEnrichmentRuleId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpBcComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSideAllocGrpBcComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSideAllocGrpBcComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocGrpBcComp EXCEPT !.tradeAllocStatus = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocGrpBcComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Side Alloc Grp Bc Comp, written one after another *)
RECURSIVE EncodeSideAllocGrpBcCompList(_)
EncodeSideAllocGrpBcCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSideAllocGrpBcComp(Head(messages)) \o EncodeSideAllocGrpBcCompList(Tail(messages))

(* As many Side Alloc Grp Bc Comp as the field that counts them says *)
RECURSIVE ReadSideAllocGrpBcCompList(_, _)
ReadSideAllocGrpBcCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSideAllocGrpBcComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSideAllocGrpBcCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Side Alloc Grp Bc Comp of each kind, for the lists that carry them *)
OneSideAllocGrpBcComp == { ZeroSideAllocGrpBcComp }

(***************************************************************************)
(* Tes Broadcast                                                           *)
(***************************************************************************)

TesBroadcast ==
    [ pad2                     : Sample(2),
      rbcHeaderComp            : RbcHeaderComp6,
      securityId               : Sample(8),
      lastPx                   : Sample(8),
      transactTime             : Sample(8),
      transBkdTime             : Sample(8),
      settlCurrFxRate          : Sample(8),
      marketSegmentId          : Sample(4),
      packageId                : Sample(4),
      tesExecId                : Sample(4),
      settlDate                : Sample(4),
      autoApprovalRuleId       : Sample(4),
      trdType                  : Sample(2),
      tradeReportType          : Sample(1),
      messageEventSource       : Sample(1),
      tradeReportText          : Sample(20),
      tradeReportId            : Sample(20),
      rootPartyExecutingFirm   : Sample(5),
      rootPartyExecutingTrader : Sample(6),
      pad2v2                   : Sample(2),
      sideAllocGrpBcComp       : SampleLists(OneSideAllocGrpBcComp),
      varText                  : SampleBytes,
      alignmentPadding         : SampleBytes ]

EncodeTesBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp6(message.rbcHeaderComp)
        \o message.securityId
        \o message.lastPx
        \o message.transactTime
        \o message.transBkdTime
        \o message.settlCurrFxRate
        \o message.marketSegmentId
        \o message.packageId
        \o message.tesExecId
        \o message.settlDate
        \o message.autoApprovalRuleId
        \o message.trdType
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.tradeReportType
        \o EncodeUIntBE(Len(message.sideAllocGrpBcComp), 1)
        \o message.messageEventSource
        \o message.tradeReportText
        \o message.tradeReportId
        \o message.rootPartyExecutingFirm
        \o message.rootPartyExecutingTrader
        \o message.pad2v2
        \o EncodeSideAllocGrpBcCompList(message.sideAllocGrpBcComp)
        \o message.varText
        \o message.alignmentPadding

DecodeTesBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp6(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transactTime == ReadBytes(lastPx.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(transactTime.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET settlCurrFxRate == ReadBytes(transBkdTime.rest, 8) IN IF ~settlCurrFxRate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(settlCurrFxRate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET packageId == ReadBytes(marketSegmentId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(packageId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET settlDate == ReadBytes(tesExecId.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET autoApprovalRuleId == ReadBytes(settlDate.rest, 4) IN IF ~autoApprovalRuleId.ok THEN Fail ELSE
    LET trdType == ReadBytes(autoApprovalRuleId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET varTextLen == ReadUIntLE(trdType.rest, 2) IN IF ~varTextLen.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(varTextLen.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET noSideAllocs == ReadUIntBE(tradeReportType.rest, 1) IN IF ~noSideAllocs.ok THEN Fail ELSE
    LET messageEventSource == ReadBytes(noSideAllocs.rest, 1) IN IF ~messageEventSource.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(messageEventSource.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET rootPartyExecutingFirm == ReadBytes(tradeReportId.rest, 5) IN IF ~rootPartyExecutingFirm.ok THEN Fail ELSE
    LET rootPartyExecutingTrader == ReadBytes(rootPartyExecutingFirm.rest, 6) IN IF ~rootPartyExecutingTrader.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(rootPartyExecutingTrader.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET sideAllocGrpBcComp == ReadSideAllocGrpBcCompList(pad2v2.rest, noSideAllocs.value) IN IF ~sideAllocGrpBcComp.ok THEN Fail ELSE
    LET varText == ReadBytes(sideAllocGrpBcComp.rest, varTextLen.value) IN IF ~varText.ok THEN Fail ELSE
    LET alignmentPadding == Ok(varText.rest, << >>) IN IF ~alignmentPadding.ok THEN Fail ELSE
    Ok([ pad2                     |-> pad2.value,
         rbcHeaderComp            |-> rbcHeaderComp.value,
         securityId               |-> securityId.value,
         lastPx                   |-> lastPx.value,
         transactTime             |-> transactTime.value,
         transBkdTime             |-> transBkdTime.value,
         settlCurrFxRate          |-> settlCurrFxRate.value,
         marketSegmentId          |-> marketSegmentId.value,
         packageId                |-> packageId.value,
         tesExecId                |-> tesExecId.value,
         settlDate                |-> settlDate.value,
         autoApprovalRuleId       |-> autoApprovalRuleId.value,
         trdType                  |-> trdType.value,
         tradeReportType          |-> tradeReportType.value,
         messageEventSource       |-> messageEventSource.value,
         tradeReportText          |-> tradeReportText.value,
         tradeReportId            |-> tradeReportId.value,
         rootPartyExecutingFirm   |-> rootPartyExecutingFirm.value,
         rootPartyExecutingTrader |-> rootPartyExecutingTrader.value,
         pad2v2                   |-> pad2v2.value,
         sideAllocGrpBcComp       |-> sideAllocGrpBcComp.value,
         varText                  |-> varText.value,
         alignmentPadding         |-> alignmentPadding.value ], alignmentPadding.rest)

ZeroTesBroadcast ==
    [ pad2                     |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp            |-> ZeroRbcHeaderComp6,
      securityId               |-> [i \in 1 .. 8 |-> 0],
      lastPx                   |-> [i \in 1 .. 8 |-> 0],
      transactTime             |-> [i \in 1 .. 8 |-> 0],
      transBkdTime             |-> [i \in 1 .. 8 |-> 0],
      settlCurrFxRate          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId          |-> [i \in 1 .. 4 |-> 0],
      packageId                |-> [i \in 1 .. 4 |-> 0],
      tesExecId                |-> [i \in 1 .. 4 |-> 0],
      settlDate                |-> [i \in 1 .. 4 |-> 0],
      autoApprovalRuleId       |-> [i \in 1 .. 4 |-> 0],
      trdType                  |-> [i \in 1 .. 2 |-> 0],
      tradeReportType          |-> [i \in 1 .. 1 |-> 0],
      messageEventSource       |-> [i \in 1 .. 1 |-> 0],
      tradeReportText          |-> [i \in 1 .. 20 |-> 0],
      tradeReportId            |-> [i \in 1 .. 20 |-> 0],
      rootPartyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad2v2                   |-> [i \in 1 .. 2 |-> 0],
      sideAllocGrpBcComp       |-> << >>,
      varText                  |-> << >>,
      alignmentPadding         |-> << >> ]

(* Tes Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTesBroadcast ==
    { ZeroTesBroadcast }
        \cup { [ZeroTesBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTesBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp6 }
        \cup { [ZeroTesBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTesBroadcast EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTesBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTesBroadcast EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroTesBroadcast EXCEPT !.settlCurrFxRate = one] : one \in Sample(8) }
        \cup { [ZeroTesBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTesBroadcast EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroTesBroadcast EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroTesBroadcast EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTesBroadcast EXCEPT !.autoApprovalRuleId = one] : one \in Sample(4) }
        \cup { [ZeroTesBroadcast EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroTesBroadcast EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTesBroadcast EXCEPT !.messageEventSource = one] : one \in Sample(1) }
        \cup { [ZeroTesBroadcast EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroTesBroadcast EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroTesBroadcast EXCEPT !.rootPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTesBroadcast EXCEPT !.rootPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroTesBroadcast EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroTesBroadcast EXCEPT !.sideAllocGrpBcComp = one] : one \in SampleLists(OneSideAllocGrpBcComp) }
        \cup { [ZeroTesBroadcast EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroTesBroadcast EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

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
(* Tes Delete Broadcast: 82 bytes                                          *)
(***************************************************************************)

TesDeleteBroadcast ==
    [ pad2               : Sample(2),
      rbcHeaderComp      : RbcHeaderComp7,
      transactTime       : Sample(8),
      marketSegmentId    : Sample(4),
      packageId          : Sample(4),
      tesExecId          : Sample(4),
      trdType            : Sample(2),
      deleteReason       : Sample(1),
      tradeReportType    : Sample(1),
      messageEventSource : Sample(1),
      tradeReportId      : Sample(20),
      pad3               : Sample(3) ]

EncodeTesDeleteBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp7(message.rbcHeaderComp)
        \o message.transactTime
        \o message.marketSegmentId
        \o message.packageId
        \o message.tesExecId
        \o message.trdType
        \o message.deleteReason
        \o message.tradeReportType
        \o message.messageEventSource
        \o message.tradeReportId
        \o message.pad3

DecodeTesDeleteBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp7(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(transactTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET packageId == ReadBytes(marketSegmentId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(packageId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET trdType == ReadBytes(tesExecId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET deleteReason == ReadBytes(trdType.rest, 1) IN IF ~deleteReason.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(deleteReason.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET messageEventSource == ReadBytes(tradeReportType.rest, 1) IN IF ~messageEventSource.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(messageEventSource.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad3 == ReadBytes(tradeReportId.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         rbcHeaderComp      |-> rbcHeaderComp.value,
         transactTime       |-> transactTime.value,
         marketSegmentId    |-> marketSegmentId.value,
         packageId          |-> packageId.value,
         tesExecId          |-> tesExecId.value,
         trdType            |-> trdType.value,
         deleteReason       |-> deleteReason.value,
         tradeReportType    |-> tradeReportType.value,
         messageEventSource |-> messageEventSource.value,
         tradeReportId      |-> tradeReportId.value,
         pad3               |-> pad3.value ], pad3.rest)

ZeroTesDeleteBroadcast ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp      |-> ZeroRbcHeaderComp7,
      transactTime       |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      packageId          |-> [i \in 1 .. 4 |-> 0],
      tesExecId          |-> [i \in 1 .. 4 |-> 0],
      trdType            |-> [i \in 1 .. 2 |-> 0],
      deleteReason       |-> [i \in 1 .. 1 |-> 0],
      tradeReportType    |-> [i \in 1 .. 1 |-> 0],
      messageEventSource |-> [i \in 1 .. 1 |-> 0],
      tradeReportId      |-> [i \in 1 .. 20 |-> 0],
      pad3               |-> [i \in 1 .. 3 |-> 0] ]

(* Tes Delete Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTesDeleteBroadcast ==
    { ZeroTesDeleteBroadcast }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp7 }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.deleteReason = one] : one \in Sample(1) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.messageEventSource = one] : one \in Sample(1) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroTesDeleteBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp8 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp8(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp8(bytes) ==
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

ZeroRbcHeaderComp8 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp8 ==
    { ZeroRbcHeaderComp8 }
        \cup { [ZeroRbcHeaderComp8 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp8 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp8 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp8 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp8 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp8 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp8 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp8 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Tes Execution Broadcast: 66 bytes                                       *)
(***************************************************************************)

TesExecutionBroadcast ==
    [ pad2               : Sample(2),
      rbcHeaderComp      : RbcHeaderComp8,
      transactTime       : Sample(8),
      marketSegmentId    : Sample(4),
      packageId          : Sample(4),
      tesExecId          : Sample(4),
      allocId            : Sample(4),
      trdType            : Sample(2),
      tradeReportType    : Sample(1),
      side               : Sample(1),
      messageEventSource : Sample(1),
      pad3               : Sample(3) ]

EncodeTesExecutionBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp8(message.rbcHeaderComp)
        \o message.transactTime
        \o message.marketSegmentId
        \o message.packageId
        \o message.tesExecId
        \o message.allocId
        \o message.trdType
        \o message.tradeReportType
        \o message.side
        \o message.messageEventSource
        \o message.pad3

DecodeTesExecutionBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp8(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(transactTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET packageId == ReadBytes(marketSegmentId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(packageId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET allocId == ReadBytes(tesExecId.rest, 4) IN IF ~allocId.ok THEN Fail ELSE
    LET trdType == ReadBytes(allocId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET side == ReadBytes(tradeReportType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET messageEventSource == ReadBytes(side.rest, 1) IN IF ~messageEventSource.ok THEN Fail ELSE
    LET pad3 == ReadBytes(messageEventSource.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         rbcHeaderComp      |-> rbcHeaderComp.value,
         transactTime       |-> transactTime.value,
         marketSegmentId    |-> marketSegmentId.value,
         packageId          |-> packageId.value,
         tesExecId          |-> tesExecId.value,
         allocId            |-> allocId.value,
         trdType            |-> trdType.value,
         tradeReportType    |-> tradeReportType.value,
         side               |-> side.value,
         messageEventSource |-> messageEventSource.value,
         pad3               |-> pad3.value ], pad3.rest)

ZeroTesExecutionBroadcast ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp      |-> ZeroRbcHeaderComp8,
      transactTime       |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      packageId          |-> [i \in 1 .. 4 |-> 0],
      tesExecId          |-> [i \in 1 .. 4 |-> 0],
      allocId            |-> [i \in 1 .. 4 |-> 0],
      trdType            |-> [i \in 1 .. 2 |-> 0],
      tradeReportType    |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      messageEventSource |-> [i \in 1 .. 1 |-> 0],
      pad3               |-> [i \in 1 .. 3 |-> 0] ]

(* Tes Execution Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTesExecutionBroadcast ==
    { ZeroTesExecutionBroadcast }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp8 }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.allocId = one] : one \in Sample(4) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.messageEventSource = one] : one \in Sample(1) }
        \cup { [ZeroTesExecutionBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }

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
(* Tes Response: 50 bytes                                                  *)
(***************************************************************************)

TesResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp9,
      tesExecId          : Sample(4),
      tradeReportId      : Sample(20) ]

EncodeTesResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp9(message.responseHeaderComp)
        \o message.tesExecId
        \o message.tradeReportId

DecodeTesResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp9(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(responseHeaderComp.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tesExecId.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value,
         tesExecId          |-> tesExecId.value,
         tradeReportId      |-> tradeReportId.value ], tradeReportId.rest)

ZeroTesResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp9,
      tesExecId          |-> [i \in 1 .. 4 |-> 0],
      tradeReportId      |-> [i \in 1 .. 20 |-> 0] ]

(* Tes Response at zero, then each field in turn at the values it is checked at *)
CheckedTesResponse ==
    { ZeroTesResponse }
        \cup { [ZeroTesResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTesResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp9 }
        \cup { [ZeroTesResponse EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroTesResponse EXCEPT !.tradeReportId = one] : one \in Sample(20) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp9 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp9(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp9(bytes) ==
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

ZeroRbcHeaderComp9 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp9 ==
    { ZeroRbcHeaderComp9 }
        \cup { [ZeroRbcHeaderComp9 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp9 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp9 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp9 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp9 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp9 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp9 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp9 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Tes Trade Broadcast: 434 bytes                                          *)
(***************************************************************************)

TesTradeBroadcast ==
    [ pad2                                        : Sample(2),
      rbcHeaderComp                               : RbcHeaderComp9,
      securityId                                  : Sample(8),
      lastPx                                      : Sample(8),
      lastQty                                     : Sample(8),
      transactTime                                : Sample(8),
      settlCurrAmt                                : Sample(8),
      sideGrossTradeAmt                           : Sample(8),
      settlCurrFxRate                             : Sample(8),
      accruedInteresAmt                           : Sample(8),
      couponRate                                  : Sample(8),
      rootPartyIdClientId                         : Sample(8),
      executingTrader                             : Sample(8),
      rootPartyIdInvestmentDecisionMaker          : Sample(8),
      packageId                                   : Sample(4),
      marketSegmentId                             : Sample(4),
      tradeId                                     : Sample(4),
      tradeDate                                   : Sample(4),
      sideTradeId                                 : Sample(4),
      rootPartyIdSessionId                        : Sample(4),
      rootPartyIdSettlementUnit                   : Sample(4),
      rootPartyIdContraUnit                       : Sample(4),
      rootPartyIdContraSettlementUnit             : Sample(4),
      origTradeId                                 : Sample(4),
      rootPartyIdExecutingUnit                    : Sample(4),
      rootPartyIdExecutingTrader                  : Sample(4),
      rootPartyIdClearingUnit                     : Sample(4),
      settlDate                                   : Sample(4),
      numDaysInterest                             : Sample(4),
      negotiationId                               : Sample(4),
      srqsRelatedTradeId                          : Sample(4),
      trdType                                     : Sample(2),
      lastMkt                                     : Sample(2),
      side                                        : Sample(1),
      tradingCapacity                             : Sample(1),
      tradeReportType                             : Sample(1),
      transferReason                              : Sample(1),
      tradePublishIndicator                       : Sample(1),
      deliveryType                                : Sample(1),
      lastCouponDeviationIndicator                : Sample(1),
      refinancingEligibilityIndicator             : Sample(1),
      clearingInstruction                         : Sample(1),
      orderAttributeLiquidityProvision            : Sample(1),
      executingTraderQualifier                    : Sample(1),
      rootPartyIdInvestmentDecisionMakerQualifier : Sample(1),
      orderOrigination                            : Sample(1),
      account                                     : Sample(2),
      freeText1                                   : Sample(12),
      freeText2                                   : Sample(12),
      freeText4                                   : Sample(16),
      settlCurrency                               : Sample(3),
      rootPartyExecutingFirm                      : Sample(5),
      rootPartyExecutingTrader                    : Sample(6),
      rootPartyClearingFirm                       : Sample(5),
      rootPartyExecutingFirmKvNumber              : Sample(4),
      rootPartySettlementAccount                  : Sample(35),
      rootPartySettlementLocation                 : Sample(3),
      rootPartySettlementFirm                     : Sample(5),
      rootPartyContraFirm                         : Sample(5),
      rootPartyContraSettlementFirm               : Sample(5),
      rootPartyContraFirmKvNumber                 : Sample(4),
      rootPartyContraSettlementAccount            : Sample(35),
      rootPartyContraSettlementLocation           : Sample(3),
      rootPartyIdExecutionVenue                   : Sample(4),
      regulatoryTradeId                           : Sample(52),
      pad3                                        : Sample(3) ]

EncodeTesTradeBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp9(message.rbcHeaderComp)
        \o message.securityId
        \o message.lastPx
        \o message.lastQty
        \o message.transactTime
        \o message.settlCurrAmt
        \o message.sideGrossTradeAmt
        \o message.settlCurrFxRate
        \o message.accruedInteresAmt
        \o message.couponRate
        \o message.rootPartyIdClientId
        \o message.executingTrader
        \o message.rootPartyIdInvestmentDecisionMaker
        \o message.packageId
        \o message.marketSegmentId
        \o message.tradeId
        \o message.tradeDate
        \o message.sideTradeId
        \o message.rootPartyIdSessionId
        \o message.rootPartyIdSettlementUnit
        \o message.rootPartyIdContraUnit
        \o message.rootPartyIdContraSettlementUnit
        \o message.origTradeId
        \o message.rootPartyIdExecutingUnit
        \o message.rootPartyIdExecutingTrader
        \o message.rootPartyIdClearingUnit
        \o message.settlDate
        \o message.numDaysInterest
        \o message.negotiationId
        \o message.srqsRelatedTradeId
        \o message.trdType
        \o message.lastMkt
        \o message.side
        \o message.tradingCapacity
        \o message.tradeReportType
        \o message.transferReason
        \o message.tradePublishIndicator
        \o message.deliveryType
        \o message.lastCouponDeviationIndicator
        \o message.refinancingEligibilityIndicator
        \o message.clearingInstruction
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.rootPartyIdInvestmentDecisionMakerQualifier
        \o message.orderOrigination
        \o message.account
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.settlCurrency
        \o message.rootPartyExecutingFirm
        \o message.rootPartyExecutingTrader
        \o message.rootPartyClearingFirm
        \o message.rootPartyExecutingFirmKvNumber
        \o message.rootPartySettlementAccount
        \o message.rootPartySettlementLocation
        \o message.rootPartySettlementFirm
        \o message.rootPartyContraFirm
        \o message.rootPartyContraSettlementFirm
        \o message.rootPartyContraFirmKvNumber
        \o message.rootPartyContraSettlementAccount
        \o message.rootPartyContraSettlementLocation
        \o message.rootPartyIdExecutionVenue
        \o message.regulatoryTradeId
        \o message.pad3

DecodeTesTradeBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp9(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET transactTime == ReadBytes(lastQty.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET settlCurrAmt == ReadBytes(transactTime.rest, 8) IN IF ~settlCurrAmt.ok THEN Fail ELSE
    LET sideGrossTradeAmt == ReadBytes(settlCurrAmt.rest, 8) IN IF ~sideGrossTradeAmt.ok THEN Fail ELSE
    LET settlCurrFxRate == ReadBytes(sideGrossTradeAmt.rest, 8) IN IF ~settlCurrFxRate.ok THEN Fail ELSE
    LET accruedInteresAmt == ReadBytes(settlCurrFxRate.rest, 8) IN IF ~accruedInteresAmt.ok THEN Fail ELSE
    LET couponRate == ReadBytes(accruedInteresAmt.rest, 8) IN IF ~couponRate.ok THEN Fail ELSE
    LET rootPartyIdClientId == ReadBytes(couponRate.rest, 8) IN IF ~rootPartyIdClientId.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(rootPartyIdClientId.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET rootPartyIdInvestmentDecisionMaker == ReadBytes(executingTrader.rest, 8) IN IF ~rootPartyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET packageId == ReadBytes(rootPartyIdInvestmentDecisionMaker.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(marketSegmentId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(tradeId.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(tradeDate.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET rootPartyIdSessionId == ReadBytes(sideTradeId.rest, 4) IN IF ~rootPartyIdSessionId.ok THEN Fail ELSE
    LET rootPartyIdSettlementUnit == ReadBytes(rootPartyIdSessionId.rest, 4) IN IF ~rootPartyIdSettlementUnit.ok THEN Fail ELSE
    LET rootPartyIdContraUnit == ReadBytes(rootPartyIdSettlementUnit.rest, 4) IN IF ~rootPartyIdContraUnit.ok THEN Fail ELSE
    LET rootPartyIdContraSettlementUnit == ReadBytes(rootPartyIdContraUnit.rest, 4) IN IF ~rootPartyIdContraSettlementUnit.ok THEN Fail ELSE
    LET origTradeId == ReadBytes(rootPartyIdContraSettlementUnit.rest, 4) IN IF ~origTradeId.ok THEN Fail ELSE
    LET rootPartyIdExecutingUnit == ReadBytes(origTradeId.rest, 4) IN IF ~rootPartyIdExecutingUnit.ok THEN Fail ELSE
    LET rootPartyIdExecutingTrader == ReadBytes(rootPartyIdExecutingUnit.rest, 4) IN IF ~rootPartyIdExecutingTrader.ok THEN Fail ELSE
    LET rootPartyIdClearingUnit == ReadBytes(rootPartyIdExecutingTrader.rest, 4) IN IF ~rootPartyIdClearingUnit.ok THEN Fail ELSE
    LET settlDate == ReadBytes(rootPartyIdClearingUnit.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET numDaysInterest == ReadBytes(settlDate.rest, 4) IN IF ~numDaysInterest.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(numDaysInterest.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET srqsRelatedTradeId == ReadBytes(negotiationId.rest, 4) IN IF ~srqsRelatedTradeId.ok THEN Fail ELSE
    LET trdType == ReadBytes(srqsRelatedTradeId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET lastMkt == ReadBytes(trdType.rest, 2) IN IF ~lastMkt.ok THEN Fail ELSE
    LET side == ReadBytes(lastMkt.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(side.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradingCapacity.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET transferReason == ReadBytes(tradeReportType.rest, 1) IN IF ~transferReason.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(transferReason.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(tradePublishIndicator.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET lastCouponDeviationIndicator == ReadBytes(deliveryType.rest, 1) IN IF ~lastCouponDeviationIndicator.ok THEN Fail ELSE
    LET refinancingEligibilityIndicator == ReadBytes(lastCouponDeviationIndicator.rest, 1) IN IF ~refinancingEligibilityIndicator.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(refinancingEligibilityIndicator.rest, 1) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(clearingInstruction.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET rootPartyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~rootPartyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(rootPartyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET account == ReadBytes(orderOrigination.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(account.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET settlCurrency == ReadBytes(freeText4.rest, 3) IN IF ~settlCurrency.ok THEN Fail ELSE
    LET rootPartyExecutingFirm == ReadBytes(settlCurrency.rest, 5) IN IF ~rootPartyExecutingFirm.ok THEN Fail ELSE
    LET rootPartyExecutingTrader == ReadBytes(rootPartyExecutingFirm.rest, 6) IN IF ~rootPartyExecutingTrader.ok THEN Fail ELSE
    LET rootPartyClearingFirm == ReadBytes(rootPartyExecutingTrader.rest, 5) IN IF ~rootPartyClearingFirm.ok THEN Fail ELSE
    LET rootPartyExecutingFirmKvNumber == ReadBytes(rootPartyClearingFirm.rest, 4) IN IF ~rootPartyExecutingFirmKvNumber.ok THEN Fail ELSE
    LET rootPartySettlementAccount == ReadBytes(rootPartyExecutingFirmKvNumber.rest, 35) IN IF ~rootPartySettlementAccount.ok THEN Fail ELSE
    LET rootPartySettlementLocation == ReadBytes(rootPartySettlementAccount.rest, 3) IN IF ~rootPartySettlementLocation.ok THEN Fail ELSE
    LET rootPartySettlementFirm == ReadBytes(rootPartySettlementLocation.rest, 5) IN IF ~rootPartySettlementFirm.ok THEN Fail ELSE
    LET rootPartyContraFirm == ReadBytes(rootPartySettlementFirm.rest, 5) IN IF ~rootPartyContraFirm.ok THEN Fail ELSE
    LET rootPartyContraSettlementFirm == ReadBytes(rootPartyContraFirm.rest, 5) IN IF ~rootPartyContraSettlementFirm.ok THEN Fail ELSE
    LET rootPartyContraFirmKvNumber == ReadBytes(rootPartyContraSettlementFirm.rest, 4) IN IF ~rootPartyContraFirmKvNumber.ok THEN Fail ELSE
    LET rootPartyContraSettlementAccount == ReadBytes(rootPartyContraFirmKvNumber.rest, 35) IN IF ~rootPartyContraSettlementAccount.ok THEN Fail ELSE
    LET rootPartyContraSettlementLocation == ReadBytes(rootPartyContraSettlementAccount.rest, 3) IN IF ~rootPartyContraSettlementLocation.ok THEN Fail ELSE
    LET rootPartyIdExecutionVenue == ReadBytes(rootPartyContraSettlementLocation.rest, 4) IN IF ~rootPartyIdExecutionVenue.ok THEN Fail ELSE
    LET regulatoryTradeId == ReadBytes(rootPartyIdExecutionVenue.rest, 52) IN IF ~regulatoryTradeId.ok THEN Fail ELSE
    LET pad3 == ReadBytes(regulatoryTradeId.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2                                        |-> pad2.value,
         rbcHeaderComp                               |-> rbcHeaderComp.value,
         securityId                                  |-> securityId.value,
         lastPx                                      |-> lastPx.value,
         lastQty                                     |-> lastQty.value,
         transactTime                                |-> transactTime.value,
         settlCurrAmt                                |-> settlCurrAmt.value,
         sideGrossTradeAmt                           |-> sideGrossTradeAmt.value,
         settlCurrFxRate                             |-> settlCurrFxRate.value,
         accruedInteresAmt                           |-> accruedInteresAmt.value,
         couponRate                                  |-> couponRate.value,
         rootPartyIdClientId                         |-> rootPartyIdClientId.value,
         executingTrader                             |-> executingTrader.value,
         rootPartyIdInvestmentDecisionMaker          |-> rootPartyIdInvestmentDecisionMaker.value,
         packageId                                   |-> packageId.value,
         marketSegmentId                             |-> marketSegmentId.value,
         tradeId                                     |-> tradeId.value,
         tradeDate                                   |-> tradeDate.value,
         sideTradeId                                 |-> sideTradeId.value,
         rootPartyIdSessionId                        |-> rootPartyIdSessionId.value,
         rootPartyIdSettlementUnit                   |-> rootPartyIdSettlementUnit.value,
         rootPartyIdContraUnit                       |-> rootPartyIdContraUnit.value,
         rootPartyIdContraSettlementUnit             |-> rootPartyIdContraSettlementUnit.value,
         origTradeId                                 |-> origTradeId.value,
         rootPartyIdExecutingUnit                    |-> rootPartyIdExecutingUnit.value,
         rootPartyIdExecutingTrader                  |-> rootPartyIdExecutingTrader.value,
         rootPartyIdClearingUnit                     |-> rootPartyIdClearingUnit.value,
         settlDate                                   |-> settlDate.value,
         numDaysInterest                             |-> numDaysInterest.value,
         negotiationId                               |-> negotiationId.value,
         srqsRelatedTradeId                          |-> srqsRelatedTradeId.value,
         trdType                                     |-> trdType.value,
         lastMkt                                     |-> lastMkt.value,
         side                                        |-> side.value,
         tradingCapacity                             |-> tradingCapacity.value,
         tradeReportType                             |-> tradeReportType.value,
         transferReason                              |-> transferReason.value,
         tradePublishIndicator                       |-> tradePublishIndicator.value,
         deliveryType                                |-> deliveryType.value,
         lastCouponDeviationIndicator                |-> lastCouponDeviationIndicator.value,
         refinancingEligibilityIndicator             |-> refinancingEligibilityIndicator.value,
         clearingInstruction                         |-> clearingInstruction.value,
         orderAttributeLiquidityProvision            |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                    |-> executingTraderQualifier.value,
         rootPartyIdInvestmentDecisionMakerQualifier |-> rootPartyIdInvestmentDecisionMakerQualifier.value,
         orderOrigination                            |-> orderOrigination.value,
         account                                     |-> account.value,
         freeText1                                   |-> freeText1.value,
         freeText2                                   |-> freeText2.value,
         freeText4                                   |-> freeText4.value,
         settlCurrency                               |-> settlCurrency.value,
         rootPartyExecutingFirm                      |-> rootPartyExecutingFirm.value,
         rootPartyExecutingTrader                    |-> rootPartyExecutingTrader.value,
         rootPartyClearingFirm                       |-> rootPartyClearingFirm.value,
         rootPartyExecutingFirmKvNumber              |-> rootPartyExecutingFirmKvNumber.value,
         rootPartySettlementAccount                  |-> rootPartySettlementAccount.value,
         rootPartySettlementLocation                 |-> rootPartySettlementLocation.value,
         rootPartySettlementFirm                     |-> rootPartySettlementFirm.value,
         rootPartyContraFirm                         |-> rootPartyContraFirm.value,
         rootPartyContraSettlementFirm               |-> rootPartyContraSettlementFirm.value,
         rootPartyContraFirmKvNumber                 |-> rootPartyContraFirmKvNumber.value,
         rootPartyContraSettlementAccount            |-> rootPartyContraSettlementAccount.value,
         rootPartyContraSettlementLocation           |-> rootPartyContraSettlementLocation.value,
         rootPartyIdExecutionVenue                   |-> rootPartyIdExecutionVenue.value,
         regulatoryTradeId                           |-> regulatoryTradeId.value,
         pad3                                        |-> pad3.value ], pad3.rest)

ZeroTesTradeBroadcast ==
    [ pad2                                        |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                               |-> ZeroRbcHeaderComp9,
      securityId                                  |-> [i \in 1 .. 8 |-> 0],
      lastPx                                      |-> [i \in 1 .. 8 |-> 0],
      lastQty                                     |-> [i \in 1 .. 8 |-> 0],
      transactTime                                |-> [i \in 1 .. 8 |-> 0],
      settlCurrAmt                                |-> [i \in 1 .. 8 |-> 0],
      sideGrossTradeAmt                           |-> [i \in 1 .. 8 |-> 0],
      settlCurrFxRate                             |-> [i \in 1 .. 8 |-> 0],
      accruedInteresAmt                           |-> [i \in 1 .. 8 |-> 0],
      couponRate                                  |-> [i \in 1 .. 8 |-> 0],
      rootPartyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      executingTrader                             |-> [i \in 1 .. 8 |-> 0],
      rootPartyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      packageId                                   |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                             |-> [i \in 1 .. 4 |-> 0],
      tradeId                                     |-> [i \in 1 .. 4 |-> 0],
      tradeDate                                   |-> [i \in 1 .. 4 |-> 0],
      sideTradeId                                 |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdSessionId                        |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdSettlementUnit                   |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdContraUnit                       |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdContraSettlementUnit             |-> [i \in 1 .. 4 |-> 0],
      origTradeId                                 |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdExecutingUnit                    |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdExecutingTrader                  |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdClearingUnit                     |-> [i \in 1 .. 4 |-> 0],
      settlDate                                   |-> [i \in 1 .. 4 |-> 0],
      numDaysInterest                             |-> [i \in 1 .. 4 |-> 0],
      negotiationId                               |-> [i \in 1 .. 4 |-> 0],
      srqsRelatedTradeId                          |-> [i \in 1 .. 4 |-> 0],
      trdType                                     |-> [i \in 1 .. 2 |-> 0],
      lastMkt                                     |-> [i \in 1 .. 2 |-> 0],
      side                                        |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                             |-> [i \in 1 .. 1 |-> 0],
      tradeReportType                             |-> [i \in 1 .. 1 |-> 0],
      transferReason                              |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator                       |-> [i \in 1 .. 1 |-> 0],
      deliveryType                                |-> [i \in 1 .. 1 |-> 0],
      lastCouponDeviationIndicator                |-> [i \in 1 .. 1 |-> 0],
      refinancingEligibilityIndicator             |-> [i \in 1 .. 1 |-> 0],
      clearingInstruction                         |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision            |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                    |-> [i \in 1 .. 1 |-> 0],
      rootPartyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                            |-> [i \in 1 .. 1 |-> 0],
      account                                     |-> [i \in 1 .. 2 |-> 0],
      freeText1                                   |-> [i \in 1 .. 12 |-> 0],
      freeText2                                   |-> [i \in 1 .. 12 |-> 0],
      freeText4                                   |-> [i \in 1 .. 16 |-> 0],
      settlCurrency                               |-> [i \in 1 .. 3 |-> 0],
      rootPartyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      rootPartyClearingFirm                       |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingFirmKvNumber              |-> [i \in 1 .. 4 |-> 0],
      rootPartySettlementAccount                  |-> [i \in 1 .. 35 |-> 0],
      rootPartySettlementLocation                 |-> [i \in 1 .. 3 |-> 0],
      rootPartySettlementFirm                     |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraFirm                         |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraSettlementFirm               |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraFirmKvNumber                 |-> [i \in 1 .. 4 |-> 0],
      rootPartyContraSettlementAccount            |-> [i \in 1 .. 35 |-> 0],
      rootPartyContraSettlementLocation           |-> [i \in 1 .. 3 |-> 0],
      rootPartyIdExecutionVenue                   |-> [i \in 1 .. 4 |-> 0],
      regulatoryTradeId                           |-> [i \in 1 .. 52 |-> 0],
      pad3                                        |-> [i \in 1 .. 3 |-> 0] ]

(* Tes Trade Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTesTradeBroadcast ==
    { ZeroTesTradeBroadcast }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp9 }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.settlCurrAmt = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.sideGrossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.settlCurrFxRate = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.accruedInteresAmt = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.couponRate = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdSettlementUnit = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdContraUnit = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdContraSettlementUnit = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.origTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdClearingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.numDaysInterest = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.srqsRelatedTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.lastMkt = one] : one \in Sample(2) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.transferReason = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.lastCouponDeviationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.refinancingEligibilityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.clearingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.settlCurrency = one] : one \in Sample(3) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyClearingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyExecutingFirmKvNumber = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartySettlementAccount = one] : one \in Sample(35) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartySettlementLocation = one] : one \in Sample(3) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartySettlementFirm = one] : one \in Sample(5) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyContraFirm = one] : one \in Sample(5) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyContraSettlementFirm = one] : one \in Sample(5) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyContraFirmKvNumber = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyContraSettlementAccount = one] : one \in Sample(35) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyContraSettlementLocation = one] : one \in Sample(3) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.rootPartyIdExecutionVenue = one] : one \in Sample(4) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.regulatoryTradeId = one] : one \in Sample(52) }
        \cup { [ZeroTesTradeBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp10 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp10(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp10(bytes) ==
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

ZeroRbcHeaderComp10 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp10 ==
    { ZeroRbcHeaderComp10 }
        \cup { [ZeroRbcHeaderComp10 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp10 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp10 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp10 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp10 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp10 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp10 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp10 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Tes Trading Session Status Broadcast: 42 bytes                          *)
(***************************************************************************)

TesTradingSessionStatusBroadcast ==
    [ pad2          : Sample(2),
      rbcHeaderComp : RbcHeaderComp10,
      tradeDate     : Sample(4),
      tradSesEvent  : Sample(1),
      pad3          : Sample(3) ]

EncodeTesTradingSessionStatusBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp10(message.rbcHeaderComp)
        \o message.tradeDate
        \o message.tradSesEvent
        \o message.pad3

DecodeTesTradingSessionStatusBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp10(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(rbcHeaderComp.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(tradeDate.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET pad3 == ReadBytes(tradSesEvent.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2          |-> pad2.value,
         rbcHeaderComp |-> rbcHeaderComp.value,
         tradeDate     |-> tradeDate.value,
         tradSesEvent  |-> tradSesEvent.value,
         pad3          |-> pad3.value ], pad3.rest)

ZeroTesTradingSessionStatusBroadcast ==
    [ pad2          |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp |-> ZeroRbcHeaderComp10,
      tradeDate     |-> [i \in 1 .. 4 |-> 0],
      tradSesEvent  |-> [i \in 1 .. 1 |-> 0],
      pad3          |-> [i \in 1 .. 3 |-> 0] ]

(* Tes Trading Session Status Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTesTradingSessionStatusBroadcast ==
    { ZeroTesTradingSessionStatusBroadcast }
        \cup { [ZeroTesTradingSessionStatusBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTesTradingSessionStatusBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp10 }
        \cup { [ZeroTesTradingSessionStatusBroadcast EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTesTradingSessionStatusBroadcast EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroTesTradingSessionStatusBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp11 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp11(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp11(bytes) ==
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

ZeroRbcHeaderComp11 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp11 ==
    { ZeroRbcHeaderComp11 }
        \cup { [ZeroRbcHeaderComp11 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp11 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp11 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp11 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp11 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp11 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp11 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp11 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Tm Trading Session Status Broadcast: 42 bytes                           *)
(***************************************************************************)

TmTradingSessionStatusBroadcast ==
    [ pad2          : Sample(2),
      rbcHeaderComp : RbcHeaderComp11,
      tradSesEvent  : Sample(1),
      pad7          : Sample(7) ]

EncodeTmTradingSessionStatusBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp11(message.rbcHeaderComp)
        \o message.tradSesEvent
        \o message.pad7

DecodeTmTradingSessionStatusBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp11(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(rbcHeaderComp.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET pad7 == ReadBytes(tradSesEvent.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2          |-> pad2.value,
         rbcHeaderComp |-> rbcHeaderComp.value,
         tradSesEvent  |-> tradSesEvent.value,
         pad7          |-> pad7.value ], pad7.rest)

ZeroTmTradingSessionStatusBroadcast ==
    [ pad2          |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp |-> ZeroRbcHeaderComp11,
      tradSesEvent  |-> [i \in 1 .. 1 |-> 0],
      pad7          |-> [i \in 1 .. 7 |-> 0] ]

(* Tm Trading Session Status Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTmTradingSessionStatusBroadcast ==
    { ZeroTmTradingSessionStatusBroadcast }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp11 }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Notif Header Comp: 8 bytes                                              *)
(***************************************************************************)

NotifHeaderComp5 ==
    [ sendingTime : Sample(8) ]

EncodeNotifHeaderComp5(message) ==
    message.sendingTime

DecodeNotifHeaderComp5(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    Ok([ sendingTime |-> sendingTime.value ], sendingTime.rest)

ZeroNotifHeaderComp5 ==
    [ sendingTime |-> [i \in 1 .. 8 |-> 0] ]

(* Notif Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedNotifHeaderComp5 ==
    { ZeroNotifHeaderComp5 }
        \cup { [ZeroNotifHeaderComp5 EXCEPT !.sendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Throttle Update Notification: 26 bytes                                  *)
(***************************************************************************)

ThrottleUpdateNotification ==
    [ pad2                    : Sample(2),
      notifHeaderComp         : NotifHeaderComp5,
      throttleTimeInterval    : Sample(8),
      throttleNoMsgs          : Sample(4),
      throttleDisconnectLimit : Sample(4) ]

EncodeThrottleUpdateNotification(message) ==
    message.pad2
        \o EncodeNotifHeaderComp5(message.notifHeaderComp)
        \o message.throttleTimeInterval
        \o message.throttleNoMsgs
        \o message.throttleDisconnectLimit

DecodeThrottleUpdateNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET notifHeaderComp == DecodeNotifHeaderComp5(pad2.rest) IN IF ~notifHeaderComp.ok THEN Fail ELSE
    LET throttleTimeInterval == ReadBytes(notifHeaderComp.rest, 8) IN IF ~throttleTimeInterval.ok THEN Fail ELSE
    LET throttleNoMsgs == ReadBytes(throttleTimeInterval.rest, 4) IN IF ~throttleNoMsgs.ok THEN Fail ELSE
    LET throttleDisconnectLimit == ReadBytes(throttleNoMsgs.rest, 4) IN IF ~throttleDisconnectLimit.ok THEN Fail ELSE
    Ok([ pad2                    |-> pad2.value,
         notifHeaderComp         |-> notifHeaderComp.value,
         throttleTimeInterval    |-> throttleTimeInterval.value,
         throttleNoMsgs          |-> throttleNoMsgs.value,
         throttleDisconnectLimit |-> throttleDisconnectLimit.value ], throttleDisconnectLimit.rest)

ZeroThrottleUpdateNotification ==
    [ pad2                    |-> [i \in 1 .. 2 |-> 0],
      notifHeaderComp         |-> ZeroNotifHeaderComp5,
      throttleTimeInterval    |-> [i \in 1 .. 8 |-> 0],
      throttleNoMsgs          |-> [i \in 1 .. 4 |-> 0],
      throttleDisconnectLimit |-> [i \in 1 .. 4 |-> 0] ]

(* Throttle Update Notification at zero, then each field in turn at the values it is checked at *)
CheckedThrottleUpdateNotification ==
    { ZeroThrottleUpdateNotification }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.notifHeaderComp = one] : one \in CheckedNotifHeaderComp5 }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.throttleTimeInterval = one] : one \in Sample(8) }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.throttleNoMsgs = one] : one \in Sample(4) }
        \cup { [ZeroThrottleUpdateNotification EXCEPT !.throttleDisconnectLimit = one] : one \in Sample(4) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp12 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp12(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp12(bytes) ==
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

ZeroRbcHeaderComp12 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp12 ==
    { ZeroRbcHeaderComp12 }
        \cup { [ZeroRbcHeaderComp12 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp12 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp12 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp12 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp12 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp12 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp12 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp12 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Trade Broadcast: 498 bytes                                              *)
(***************************************************************************)

TradeBroadcast ==
    [ pad2                                        : Sample(2),
      rbcHeaderComp                               : RbcHeaderComp12,
      securityId                                  : Sample(8),
      price                                       : Sample(8),
      lastPx                                      : Sample(8),
      lastQty                                     : Sample(8),
      settlCurrAmt                                : Sample(8),
      settlCurrFxRate                             : Sample(8),
      transactTime                                : Sample(8),
      orderId                                     : Sample(8),
      clOrdId                                     : Sample(8),
      leavesQty                                   : Sample(8),
      cumQty                                      : Sample(8),
      sideGrossTradeAmt                           : Sample(8),
      accruedInteresAmt                           : Sample(8),
      couponRate                                  : Sample(8),
      rootPartyIdClientId                         : Sample(8),
      executingTrader                             : Sample(8),
      rootPartyIdInvestmentDecisionMaker          : Sample(8),
      tradeId                                     : Sample(4),
      origTradeId                                 : Sample(4),
      rootPartyIdExecutingUnit                    : Sample(4),
      rootPartyIdSessionId                        : Sample(4),
      rootPartyIdExecutingTrader                  : Sample(4),
      rootPartyIdSettlementUnit                   : Sample(4),
      rootPartyIdClearingUnit                     : Sample(4),
      rootPartyIdContraUnit                       : Sample(4),
      rootPartyIdContraSettlementUnit             : Sample(4),
      partyIdSpecialistTrader                     : Sample(4),
      orderIdSfx                                  : Sample(4),
      marketSegmentId                             : Sample(4),
      sideTradeId                                 : Sample(4),
      sideTradeReportId                           : Sample(4),
      tradeNumber                                 : Sample(4),
      matchDate                                   : Sample(4),
      settlDate                                   : Sample(4),
      trdMatchId                                  : Sample(4),
      numDaysInterest                             : Sample(4),
      lastMkt                                     : Sample(2),
      tradeReportType                             : Sample(1),
      transferReason                              : Sample(1),
      matchType                                   : Sample(1),
      matchSubType                                : Sample(1),
      side                                        : Sample(1),
      sideLiquidityInd                            : Sample(1),
      deliveryType                                : Sample(1),
      tradingCapacity                             : Sample(1),
      lastCouponDeviationIndicator                : Sample(1),
      refinancingEligibilityIndicator             : Sample(1),
      clearingInstruction                         : Sample(1),
      orderOrigination                            : Sample(1),
      orderAttributeLiquidityProvision            : Sample(1),
      executingTraderQualifier                    : Sample(1),
      rootPartyIdInvestmentDecisionMakerQualifier : Sample(1),
      account                                     : Sample(2),
      settlCurrency                               : Sample(3),
      currency                                    : Sample(3),
      freeText1                                   : Sample(12),
      freeText2                                   : Sample(12),
      freeText4                                   : Sample(16),
      orderCategory                               : Sample(1),
      ordType                                     : Sample(1),
      rootPartyExecutingFirm                      : Sample(5),
      rootPartyExecutingTrader                    : Sample(6),
      rootPartyClearingFirm                       : Sample(5),
      rootPartyExecutingFirmKvNumber              : Sample(4),
      rootPartySettlementAccount                  : Sample(35),
      rootPartySettlementLocation                 : Sample(3),
      rootPartySettlementFirm                     : Sample(5),
      rootPartyContraFirm                         : Sample(5),
      rootPartyContraSettlementFirm               : Sample(5),
      rootPartyContraFirmKvNumber                 : Sample(4),
      rootPartyContraSettlementAccount            : Sample(35),
      rootPartyContraSettlementLocation           : Sample(3),
      partySpecialistFirm                         : Sample(5),
      partySpecialistTrader                       : Sample(6),
      regulatoryTradeId                           : Sample(52),
      rootPartyIdExecutionVenue                   : Sample(4),
      pad3                                        : Sample(3) ]

EncodeTradeBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp12(message.rbcHeaderComp)
        \o message.securityId
        \o message.price
        \o message.lastPx
        \o message.lastQty
        \o message.settlCurrAmt
        \o message.settlCurrFxRate
        \o message.transactTime
        \o message.orderId
        \o message.clOrdId
        \o message.leavesQty
        \o message.cumQty
        \o message.sideGrossTradeAmt
        \o message.accruedInteresAmt
        \o message.couponRate
        \o message.rootPartyIdClientId
        \o message.executingTrader
        \o message.rootPartyIdInvestmentDecisionMaker
        \o message.tradeId
        \o message.origTradeId
        \o message.rootPartyIdExecutingUnit
        \o message.rootPartyIdSessionId
        \o message.rootPartyIdExecutingTrader
        \o message.rootPartyIdSettlementUnit
        \o message.rootPartyIdClearingUnit
        \o message.rootPartyIdContraUnit
        \o message.rootPartyIdContraSettlementUnit
        \o message.partyIdSpecialistTrader
        \o message.orderIdSfx
        \o message.marketSegmentId
        \o message.sideTradeId
        \o message.sideTradeReportId
        \o message.tradeNumber
        \o message.matchDate
        \o message.settlDate
        \o message.trdMatchId
        \o message.numDaysInterest
        \o message.lastMkt
        \o message.tradeReportType
        \o message.transferReason
        \o message.matchType
        \o message.matchSubType
        \o message.side
        \o message.sideLiquidityInd
        \o message.deliveryType
        \o message.tradingCapacity
        \o message.lastCouponDeviationIndicator
        \o message.refinancingEligibilityIndicator
        \o message.clearingInstruction
        \o message.orderOrigination
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.rootPartyIdInvestmentDecisionMakerQualifier
        \o message.account
        \o message.settlCurrency
        \o message.currency
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.orderCategory
        \o message.ordType
        \o message.rootPartyExecutingFirm
        \o message.rootPartyExecutingTrader
        \o message.rootPartyClearingFirm
        \o message.rootPartyExecutingFirmKvNumber
        \o message.rootPartySettlementAccount
        \o message.rootPartySettlementLocation
        \o message.rootPartySettlementFirm
        \o message.rootPartyContraFirm
        \o message.rootPartyContraSettlementFirm
        \o message.rootPartyContraFirmKvNumber
        \o message.rootPartyContraSettlementAccount
        \o message.rootPartyContraSettlementLocation
        \o message.partySpecialistFirm
        \o message.partySpecialistTrader
        \o message.regulatoryTradeId
        \o message.rootPartyIdExecutionVenue
        \o message.pad3

DecodeTradeBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp12(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET lastPx == ReadBytes(price.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET settlCurrAmt == ReadBytes(lastQty.rest, 8) IN IF ~settlCurrAmt.ok THEN Fail ELSE
    LET settlCurrFxRate == ReadBytes(settlCurrAmt.rest, 8) IN IF ~settlCurrFxRate.ok THEN Fail ELSE
    LET transactTime == ReadBytes(settlCurrFxRate.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(clOrdId.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 8) IN IF ~cumQty.ok THEN Fail ELSE
    LET sideGrossTradeAmt == ReadBytes(cumQty.rest, 8) IN IF ~sideGrossTradeAmt.ok THEN Fail ELSE
    LET accruedInteresAmt == ReadBytes(sideGrossTradeAmt.rest, 8) IN IF ~accruedInteresAmt.ok THEN Fail ELSE
    LET couponRate == ReadBytes(accruedInteresAmt.rest, 8) IN IF ~couponRate.ok THEN Fail ELSE
    LET rootPartyIdClientId == ReadBytes(couponRate.rest, 8) IN IF ~rootPartyIdClientId.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(rootPartyIdClientId.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET rootPartyIdInvestmentDecisionMaker == ReadBytes(executingTrader.rest, 8) IN IF ~rootPartyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET tradeId == ReadBytes(rootPartyIdInvestmentDecisionMaker.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET origTradeId == ReadBytes(tradeId.rest, 4) IN IF ~origTradeId.ok THEN Fail ELSE
    LET rootPartyIdExecutingUnit == ReadBytes(origTradeId.rest, 4) IN IF ~rootPartyIdExecutingUnit.ok THEN Fail ELSE
    LET rootPartyIdSessionId == ReadBytes(rootPartyIdExecutingUnit.rest, 4) IN IF ~rootPartyIdSessionId.ok THEN Fail ELSE
    LET rootPartyIdExecutingTrader == ReadBytes(rootPartyIdSessionId.rest, 4) IN IF ~rootPartyIdExecutingTrader.ok THEN Fail ELSE
    LET rootPartyIdSettlementUnit == ReadBytes(rootPartyIdExecutingTrader.rest, 4) IN IF ~rootPartyIdSettlementUnit.ok THEN Fail ELSE
    LET rootPartyIdClearingUnit == ReadBytes(rootPartyIdSettlementUnit.rest, 4) IN IF ~rootPartyIdClearingUnit.ok THEN Fail ELSE
    LET rootPartyIdContraUnit == ReadBytes(rootPartyIdClearingUnit.rest, 4) IN IF ~rootPartyIdContraUnit.ok THEN Fail ELSE
    LET rootPartyIdContraSettlementUnit == ReadBytes(rootPartyIdContraUnit.rest, 4) IN IF ~rootPartyIdContraSettlementUnit.ok THEN Fail ELSE
    LET partyIdSpecialistTrader == ReadBytes(rootPartyIdContraSettlementUnit.rest, 4) IN IF ~partyIdSpecialistTrader.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(partyIdSpecialistTrader.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderIdSfx.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(marketSegmentId.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET sideTradeReportId == ReadBytes(sideTradeId.rest, 4) IN IF ~sideTradeReportId.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(sideTradeReportId.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET matchDate == ReadBytes(tradeNumber.rest, 4) IN IF ~matchDate.ok THEN Fail ELSE
    LET settlDate == ReadBytes(matchDate.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(settlDate.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET numDaysInterest == ReadBytes(trdMatchId.rest, 4) IN IF ~numDaysInterest.ok THEN Fail ELSE
    LET lastMkt == ReadBytes(numDaysInterest.rest, 2) IN IF ~lastMkt.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(lastMkt.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET transferReason == ReadBytes(tradeReportType.rest, 1) IN IF ~transferReason.ok THEN Fail ELSE
    LET matchType == ReadBytes(transferReason.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET matchSubType == ReadBytes(matchType.rest, 1) IN IF ~matchSubType.ok THEN Fail ELSE
    LET side == ReadBytes(matchSubType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sideLiquidityInd == ReadBytes(side.rest, 1) IN IF ~sideLiquidityInd.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(sideLiquidityInd.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(deliveryType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET lastCouponDeviationIndicator == ReadBytes(tradingCapacity.rest, 1) IN IF ~lastCouponDeviationIndicator.ok THEN Fail ELSE
    LET refinancingEligibilityIndicator == ReadBytes(lastCouponDeviationIndicator.rest, 1) IN IF ~refinancingEligibilityIndicator.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(refinancingEligibilityIndicator.rest, 1) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(clearingInstruction.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(orderOrigination.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET rootPartyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~rootPartyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET account == ReadBytes(rootPartyIdInvestmentDecisionMakerQualifier.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET settlCurrency == ReadBytes(account.rest, 3) IN IF ~settlCurrency.ok THEN Fail ELSE
    LET currency == ReadBytes(settlCurrency.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(currency.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET orderCategory == ReadBytes(freeText4.rest, 1) IN IF ~orderCategory.ok THEN Fail ELSE
    LET ordType == ReadBytes(orderCategory.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET rootPartyExecutingFirm == ReadBytes(ordType.rest, 5) IN IF ~rootPartyExecutingFirm.ok THEN Fail ELSE
    LET rootPartyExecutingTrader == ReadBytes(rootPartyExecutingFirm.rest, 6) IN IF ~rootPartyExecutingTrader.ok THEN Fail ELSE
    LET rootPartyClearingFirm == ReadBytes(rootPartyExecutingTrader.rest, 5) IN IF ~rootPartyClearingFirm.ok THEN Fail ELSE
    LET rootPartyExecutingFirmKvNumber == ReadBytes(rootPartyClearingFirm.rest, 4) IN IF ~rootPartyExecutingFirmKvNumber.ok THEN Fail ELSE
    LET rootPartySettlementAccount == ReadBytes(rootPartyExecutingFirmKvNumber.rest, 35) IN IF ~rootPartySettlementAccount.ok THEN Fail ELSE
    LET rootPartySettlementLocation == ReadBytes(rootPartySettlementAccount.rest, 3) IN IF ~rootPartySettlementLocation.ok THEN Fail ELSE
    LET rootPartySettlementFirm == ReadBytes(rootPartySettlementLocation.rest, 5) IN IF ~rootPartySettlementFirm.ok THEN Fail ELSE
    LET rootPartyContraFirm == ReadBytes(rootPartySettlementFirm.rest, 5) IN IF ~rootPartyContraFirm.ok THEN Fail ELSE
    LET rootPartyContraSettlementFirm == ReadBytes(rootPartyContraFirm.rest, 5) IN IF ~rootPartyContraSettlementFirm.ok THEN Fail ELSE
    LET rootPartyContraFirmKvNumber == ReadBytes(rootPartyContraSettlementFirm.rest, 4) IN IF ~rootPartyContraFirmKvNumber.ok THEN Fail ELSE
    LET rootPartyContraSettlementAccount == ReadBytes(rootPartyContraFirmKvNumber.rest, 35) IN IF ~rootPartyContraSettlementAccount.ok THEN Fail ELSE
    LET rootPartyContraSettlementLocation == ReadBytes(rootPartyContraSettlementAccount.rest, 3) IN IF ~rootPartyContraSettlementLocation.ok THEN Fail ELSE
    LET partySpecialistFirm == ReadBytes(rootPartyContraSettlementLocation.rest, 5) IN IF ~partySpecialistFirm.ok THEN Fail ELSE
    LET partySpecialistTrader == ReadBytes(partySpecialistFirm.rest, 6) IN IF ~partySpecialistTrader.ok THEN Fail ELSE
    LET regulatoryTradeId == ReadBytes(partySpecialistTrader.rest, 52) IN IF ~regulatoryTradeId.ok THEN Fail ELSE
    LET rootPartyIdExecutionVenue == ReadBytes(regulatoryTradeId.rest, 4) IN IF ~rootPartyIdExecutionVenue.ok THEN Fail ELSE
    LET pad3 == ReadBytes(rootPartyIdExecutionVenue.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2                                        |-> pad2.value,
         rbcHeaderComp                               |-> rbcHeaderComp.value,
         securityId                                  |-> securityId.value,
         price                                       |-> price.value,
         lastPx                                      |-> lastPx.value,
         lastQty                                     |-> lastQty.value,
         settlCurrAmt                                |-> settlCurrAmt.value,
         settlCurrFxRate                             |-> settlCurrFxRate.value,
         transactTime                                |-> transactTime.value,
         orderId                                     |-> orderId.value,
         clOrdId                                     |-> clOrdId.value,
         leavesQty                                   |-> leavesQty.value,
         cumQty                                      |-> cumQty.value,
         sideGrossTradeAmt                           |-> sideGrossTradeAmt.value,
         accruedInteresAmt                           |-> accruedInteresAmt.value,
         couponRate                                  |-> couponRate.value,
         rootPartyIdClientId                         |-> rootPartyIdClientId.value,
         executingTrader                             |-> executingTrader.value,
         rootPartyIdInvestmentDecisionMaker          |-> rootPartyIdInvestmentDecisionMaker.value,
         tradeId                                     |-> tradeId.value,
         origTradeId                                 |-> origTradeId.value,
         rootPartyIdExecutingUnit                    |-> rootPartyIdExecutingUnit.value,
         rootPartyIdSessionId                        |-> rootPartyIdSessionId.value,
         rootPartyIdExecutingTrader                  |-> rootPartyIdExecutingTrader.value,
         rootPartyIdSettlementUnit                   |-> rootPartyIdSettlementUnit.value,
         rootPartyIdClearingUnit                     |-> rootPartyIdClearingUnit.value,
         rootPartyIdContraUnit                       |-> rootPartyIdContraUnit.value,
         rootPartyIdContraSettlementUnit             |-> rootPartyIdContraSettlementUnit.value,
         partyIdSpecialistTrader                     |-> partyIdSpecialistTrader.value,
         orderIdSfx                                  |-> orderIdSfx.value,
         marketSegmentId                             |-> marketSegmentId.value,
         sideTradeId                                 |-> sideTradeId.value,
         sideTradeReportId                           |-> sideTradeReportId.value,
         tradeNumber                                 |-> tradeNumber.value,
         matchDate                                   |-> matchDate.value,
         settlDate                                   |-> settlDate.value,
         trdMatchId                                  |-> trdMatchId.value,
         numDaysInterest                             |-> numDaysInterest.value,
         lastMkt                                     |-> lastMkt.value,
         tradeReportType                             |-> tradeReportType.value,
         transferReason                              |-> transferReason.value,
         matchType                                   |-> matchType.value,
         matchSubType                                |-> matchSubType.value,
         side                                        |-> side.value,
         sideLiquidityInd                            |-> sideLiquidityInd.value,
         deliveryType                                |-> deliveryType.value,
         tradingCapacity                             |-> tradingCapacity.value,
         lastCouponDeviationIndicator                |-> lastCouponDeviationIndicator.value,
         refinancingEligibilityIndicator             |-> refinancingEligibilityIndicator.value,
         clearingInstruction                         |-> clearingInstruction.value,
         orderOrigination                            |-> orderOrigination.value,
         orderAttributeLiquidityProvision            |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                    |-> executingTraderQualifier.value,
         rootPartyIdInvestmentDecisionMakerQualifier |-> rootPartyIdInvestmentDecisionMakerQualifier.value,
         account                                     |-> account.value,
         settlCurrency                               |-> settlCurrency.value,
         currency                                    |-> currency.value,
         freeText1                                   |-> freeText1.value,
         freeText2                                   |-> freeText2.value,
         freeText4                                   |-> freeText4.value,
         orderCategory                               |-> orderCategory.value,
         ordType                                     |-> ordType.value,
         rootPartyExecutingFirm                      |-> rootPartyExecutingFirm.value,
         rootPartyExecutingTrader                    |-> rootPartyExecutingTrader.value,
         rootPartyClearingFirm                       |-> rootPartyClearingFirm.value,
         rootPartyExecutingFirmKvNumber              |-> rootPartyExecutingFirmKvNumber.value,
         rootPartySettlementAccount                  |-> rootPartySettlementAccount.value,
         rootPartySettlementLocation                 |-> rootPartySettlementLocation.value,
         rootPartySettlementFirm                     |-> rootPartySettlementFirm.value,
         rootPartyContraFirm                         |-> rootPartyContraFirm.value,
         rootPartyContraSettlementFirm               |-> rootPartyContraSettlementFirm.value,
         rootPartyContraFirmKvNumber                 |-> rootPartyContraFirmKvNumber.value,
         rootPartyContraSettlementAccount            |-> rootPartyContraSettlementAccount.value,
         rootPartyContraSettlementLocation           |-> rootPartyContraSettlementLocation.value,
         partySpecialistFirm                         |-> partySpecialistFirm.value,
         partySpecialistTrader                       |-> partySpecialistTrader.value,
         regulatoryTradeId                           |-> regulatoryTradeId.value,
         rootPartyIdExecutionVenue                   |-> rootPartyIdExecutionVenue.value,
         pad3                                        |-> pad3.value ], pad3.rest)

ZeroTradeBroadcast ==
    [ pad2                                        |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                               |-> ZeroRbcHeaderComp12,
      securityId                                  |-> [i \in 1 .. 8 |-> 0],
      price                                       |-> [i \in 1 .. 8 |-> 0],
      lastPx                                      |-> [i \in 1 .. 8 |-> 0],
      lastQty                                     |-> [i \in 1 .. 8 |-> 0],
      settlCurrAmt                                |-> [i \in 1 .. 8 |-> 0],
      settlCurrFxRate                             |-> [i \in 1 .. 8 |-> 0],
      transactTime                                |-> [i \in 1 .. 8 |-> 0],
      orderId                                     |-> [i \in 1 .. 8 |-> 0],
      clOrdId                                     |-> [i \in 1 .. 8 |-> 0],
      leavesQty                                   |-> [i \in 1 .. 8 |-> 0],
      cumQty                                      |-> [i \in 1 .. 8 |-> 0],
      sideGrossTradeAmt                           |-> [i \in 1 .. 8 |-> 0],
      accruedInteresAmt                           |-> [i \in 1 .. 8 |-> 0],
      couponRate                                  |-> [i \in 1 .. 8 |-> 0],
      rootPartyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      executingTrader                             |-> [i \in 1 .. 8 |-> 0],
      rootPartyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      tradeId                                     |-> [i \in 1 .. 4 |-> 0],
      origTradeId                                 |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdExecutingUnit                    |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdSessionId                        |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdExecutingTrader                  |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdSettlementUnit                   |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdClearingUnit                     |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdContraUnit                       |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdContraSettlementUnit             |-> [i \in 1 .. 4 |-> 0],
      partyIdSpecialistTrader                     |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx                                  |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                             |-> [i \in 1 .. 4 |-> 0],
      sideTradeId                                 |-> [i \in 1 .. 4 |-> 0],
      sideTradeReportId                           |-> [i \in 1 .. 4 |-> 0],
      tradeNumber                                 |-> [i \in 1 .. 4 |-> 0],
      matchDate                                   |-> [i \in 1 .. 4 |-> 0],
      settlDate                                   |-> [i \in 1 .. 4 |-> 0],
      trdMatchId                                  |-> [i \in 1 .. 4 |-> 0],
      numDaysInterest                             |-> [i \in 1 .. 4 |-> 0],
      lastMkt                                     |-> [i \in 1 .. 2 |-> 0],
      tradeReportType                             |-> [i \in 1 .. 1 |-> 0],
      transferReason                              |-> [i \in 1 .. 1 |-> 0],
      matchType                                   |-> [i \in 1 .. 1 |-> 0],
      matchSubType                                |-> [i \in 1 .. 1 |-> 0],
      side                                        |-> [i \in 1 .. 1 |-> 0],
      sideLiquidityInd                            |-> [i \in 1 .. 1 |-> 0],
      deliveryType                                |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                             |-> [i \in 1 .. 1 |-> 0],
      lastCouponDeviationIndicator                |-> [i \in 1 .. 1 |-> 0],
      refinancingEligibilityIndicator             |-> [i \in 1 .. 1 |-> 0],
      clearingInstruction                         |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                            |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision            |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                    |-> [i \in 1 .. 1 |-> 0],
      rootPartyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      account                                     |-> [i \in 1 .. 2 |-> 0],
      settlCurrency                               |-> [i \in 1 .. 3 |-> 0],
      currency                                    |-> [i \in 1 .. 3 |-> 0],
      freeText1                                   |-> [i \in 1 .. 12 |-> 0],
      freeText2                                   |-> [i \in 1 .. 12 |-> 0],
      freeText4                                   |-> [i \in 1 .. 16 |-> 0],
      orderCategory                               |-> [i \in 1 .. 1 |-> 0],
      ordType                                     |-> [i \in 1 .. 1 |-> 0],
      rootPartyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      rootPartyClearingFirm                       |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingFirmKvNumber              |-> [i \in 1 .. 4 |-> 0],
      rootPartySettlementAccount                  |-> [i \in 1 .. 35 |-> 0],
      rootPartySettlementLocation                 |-> [i \in 1 .. 3 |-> 0],
      rootPartySettlementFirm                     |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraFirm                         |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraSettlementFirm               |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraFirmKvNumber                 |-> [i \in 1 .. 4 |-> 0],
      rootPartyContraSettlementAccount            |-> [i \in 1 .. 35 |-> 0],
      rootPartyContraSettlementLocation           |-> [i \in 1 .. 3 |-> 0],
      partySpecialistFirm                         |-> [i \in 1 .. 5 |-> 0],
      partySpecialistTrader                       |-> [i \in 1 .. 6 |-> 0],
      regulatoryTradeId                           |-> [i \in 1 .. 52 |-> 0],
      rootPartyIdExecutionVenue                   |-> [i \in 1 .. 4 |-> 0],
      pad3                                        |-> [i \in 1 .. 3 |-> 0] ]

(* Trade Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTradeBroadcast ==
    { ZeroTradeBroadcast }
        \cup { [ZeroTradeBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp12 }
        \cup { [ZeroTradeBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.settlCurrAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.settlCurrFxRate = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.cumQty = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideGrossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.accruedInteresAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.couponRate = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.origTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdSettlementUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdClearingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdContraUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdContraSettlementUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.partyIdSpecialistTrader = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideTradeReportId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.matchDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.numDaysInterest = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.lastMkt = one] : one \in Sample(2) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.transferReason = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.matchSubType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.lastCouponDeviationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.refinancingEligibilityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.clearingInstruction = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroTradeBroadcast EXCEPT !.settlCurrency = one] : one \in Sample(3) }
        \cup { [ZeroTradeBroadcast EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroTradeBroadcast EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroTradeBroadcast EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroTradeBroadcast EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyClearingFirm = one] : one \in Sample(5) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyExecutingFirmKvNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartySettlementAccount = one] : one \in Sample(35) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartySettlementLocation = one] : one \in Sample(3) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartySettlementFirm = one] : one \in Sample(5) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyContraFirm = one] : one \in Sample(5) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyContraSettlementFirm = one] : one \in Sample(5) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyContraFirmKvNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyContraSettlementAccount = one] : one \in Sample(35) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyContraSettlementLocation = one] : one \in Sample(3) }
        \cup { [ZeroTradeBroadcast EXCEPT !.partySpecialistFirm = one] : one \in Sample(5) }
        \cup { [ZeroTradeBroadcast EXCEPT !.partySpecialistTrader = one] : one \in Sample(6) }
        \cup { [ZeroTradeBroadcast EXCEPT !.regulatoryTradeId = one] : one \in Sample(52) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdExecutionVenue = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp19 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp19(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp19(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp19 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp19 ==
    { ZeroRbcHeaderMeComp19 }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp19 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Trading Session Status Broadcast: 90 bytes                              *)
(***************************************************************************)

TradingSessionStatusBroadcast ==
    [ pad2             : Sample(2),
      rbcHeaderMeComp  : RbcHeaderMeComp19,
      marketSegmentId  : Sample(4),
      tradeDate        : Sample(4),
      tradSesEvent     : Sample(1),
      refApplLastMsgId : Sample(16),
      pad7             : Sample(7) ]

EncodeTradingSessionStatusBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp19(message.rbcHeaderMeComp)
        \o message.marketSegmentId
        \o message.tradeDate
        \o message.tradSesEvent
        \o message.refApplLastMsgId
        \o message.pad7

DecodeTradingSessionStatusBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp19(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(rbcHeaderMeComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(tradeDate.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET refApplLastMsgId == ReadBytes(tradSesEvent.rest, 16) IN IF ~refApplLastMsgId.ok THEN Fail ELSE
    LET pad7 == ReadBytes(refApplLastMsgId.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2             |-> pad2.value,
         rbcHeaderMeComp  |-> rbcHeaderMeComp.value,
         marketSegmentId  |-> marketSegmentId.value,
         tradeDate        |-> tradeDate.value,
         tradSesEvent     |-> tradSesEvent.value,
         refApplLastMsgId |-> refApplLastMsgId.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroTradingSessionStatusBroadcast ==
    [ pad2             |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp  |-> ZeroRbcHeaderMeComp19,
      marketSegmentId  |-> [i \in 1 .. 4 |-> 0],
      tradeDate        |-> [i \in 1 .. 4 |-> 0],
      tradSesEvent     |-> [i \in 1 .. 1 |-> 0],
      refApplLastMsgId |-> [i \in 1 .. 16 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Trading Session Status Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusBroadcast ==
    { ZeroTradingSessionStatusBroadcast }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp19 }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.refApplLastMsgId = one] : one \in Sample(16) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Rbc Header Me Comp: 56 bytes                                            *)
(***************************************************************************)

RbcHeaderMeComp20 ==
    [ trdRegTsTimeOut : Sample(8),
      notificationIn  : Sample(8),
      sendingTime     : Sample(8),
      applSubId       : Sample(4),
      partitionId     : Sample(2),
      applMsgId       : Sample(16),
      applId          : Sample(1),
      applResendFlag  : Sample(1),
      lastFragment    : Sample(1),
      pad7            : Sample(7) ]

EncodeRbcHeaderMeComp20(message) ==
    message.trdRegTsTimeOut
        \o message.notificationIn
        \o message.sendingTime
        \o message.applSubId
        \o message.partitionId
        \o message.applMsgId
        \o message.applId
        \o message.applResendFlag
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderMeComp20(bytes) ==
    LET trdRegTsTimeOut == ReadBytes(bytes, 8) IN IF ~trdRegTsTimeOut.ok THEN Fail ELSE
    LET notificationIn == ReadBytes(trdRegTsTimeOut.rest, 8) IN IF ~notificationIn.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(notificationIn.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET applSubId == ReadBytes(sendingTime.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSubId.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET applMsgId == ReadBytes(partitionId.rest, 16) IN IF ~applMsgId.ok THEN Fail ELSE
    LET applId == ReadBytes(applMsgId.rest, 1) IN IF ~applId.ok THEN Fail ELSE
    LET applResendFlag == ReadBytes(applId.rest, 1) IN IF ~applResendFlag.ok THEN Fail ELSE
    LET lastFragment == ReadBytes(applResendFlag.rest, 1) IN IF ~lastFragment.ok THEN Fail ELSE
    LET pad7 == ReadBytes(lastFragment.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ trdRegTsTimeOut |-> trdRegTsTimeOut.value,
         notificationIn  |-> notificationIn.value,
         sendingTime     |-> sendingTime.value,
         applSubId       |-> applSubId.value,
         partitionId     |-> partitionId.value,
         applMsgId       |-> applMsgId.value,
         applId          |-> applId.value,
         applResendFlag  |-> applResendFlag.value,
         lastFragment    |-> lastFragment.value,
         pad7            |-> pad7.value ], pad7.rest)

ZeroRbcHeaderMeComp20 ==
    [ trdRegTsTimeOut |-> [i \in 1 .. 8 |-> 0],
      notificationIn  |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      applSubId       |-> [i \in 1 .. 4 |-> 0],
      partitionId     |-> [i \in 1 .. 2 |-> 0],
      applMsgId       |-> [i \in 1 .. 16 |-> 0],
      applId          |-> [i \in 1 .. 1 |-> 0],
      applResendFlag  |-> [i \in 1 .. 1 |-> 0],
      lastFragment    |-> [i \in 1 .. 1 |-> 0],
      pad7            |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Me Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderMeComp20 ==
    { ZeroRbcHeaderMeComp20 }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.notificationIn = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.applMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderMeComp20 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Trailing Stop Update Notification: 154 bytes                            *)
(***************************************************************************)

TrailingStopUpdateNotification ==
    [ pad2                  : Sample(2),
      rbcHeaderMeComp       : RbcHeaderMeComp20,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      stopPx                : Sample(8),
      orderQty              : Sample(8),
      orderIdSfx            : Sample(4),
      marketSegmentId       : Sample(4),
      execRestatementReason : Sample(2),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      side                  : Sample(1),
      fixClOrdId            : Sample(20),
      pad7                  : Sample(7) ]

EncodeTrailingStopUpdateNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp20(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.stopPx
        \o message.orderQty
        \o message.orderIdSfx
        \o message.marketSegmentId
        \o message.execRestatementReason
        \o message.ordStatus
        \o message.execType
        \o message.side
        \o message.fixClOrdId
        \o message.pad7

DecodeTrailingStopUpdateNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp20(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET stopPx == ReadBytes(execId.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET orderQty == ReadBytes(stopPx.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(orderQty.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderIdSfx.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(marketSegmentId.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execRestatementReason.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET side == ReadBytes(execType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(side.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET pad7 == ReadBytes(fixClOrdId.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         rbcHeaderMeComp       |-> rbcHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         stopPx                |-> stopPx.value,
         orderQty              |-> orderQty.value,
         orderIdSfx            |-> orderIdSfx.value,
         marketSegmentId       |-> marketSegmentId.value,
         execRestatementReason |-> execRestatementReason.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         side                  |-> side.value,
         fixClOrdId            |-> fixClOrdId.value,
         pad7                  |-> pad7.value ], pad7.rest)

ZeroTrailingStopUpdateNotification ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp       |-> ZeroRbcHeaderMeComp20,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      orderQty              |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      fixClOrdId            |-> [i \in 1 .. 20 |-> 0],
      pad7                  |-> [i \in 1 .. 7 |-> 0] ]

(* Trailing Stop Update Notification at zero, then each field in turn at the values it is checked at *)
CheckedTrailingStopUpdateNotification ==
    { ZeroTrailingStopUpdateNotification }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp20 }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Unsubscribe Response: 26 bytes                                          *)
(***************************************************************************)

UnsubscribeResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp10 ]

EncodeUnsubscribeResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp10(message.responseHeaderComp)

DecodeUnsubscribeResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp10(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroUnsubscribeResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp10 ]

(* Unsubscribe Response at zero, then each field in turn at the values it is checked at *)
CheckedUnsubscribeResponse ==
    { ZeroUnsubscribeResponse }
        \cup { [ZeroUnsubscribeResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUnsubscribeResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp10 }

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
(* User Login Response: 26 bytes                                           *)
(***************************************************************************)

UserLoginResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp11 ]

EncodeUserLoginResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp11(message.responseHeaderComp)

DecodeUserLoginResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp11(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroUserLoginResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp11 ]

(* User Login Response at zero, then each field in turn at the values it is checked at *)
CheckedUserLoginResponse ==
    { ZeroUserLoginResponse }
        \cup { [ZeroUserLoginResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLoginResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp11 }

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
(* User Logout Response: 26 bytes                                          *)
(***************************************************************************)

UserLogoutResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp12 ]

EncodeUserLogoutResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp12(message.responseHeaderComp)

DecodeUserLogoutResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp12(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroUserLogoutResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp12 ]

(* User Logout Response at zero, then each field in turn at the values it is checked at *)
CheckedUserLogoutResponse ==
    { ZeroUserLogoutResponse }
        \cup { [ZeroUserLogoutResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLogoutResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp12 }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp13 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp13(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp13(bytes) ==
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

ZeroRbcHeaderComp13 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp13 ==
    { ZeroRbcHeaderComp13 }
        \cup { [ZeroRbcHeaderComp13 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp13 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp13 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp13 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp13 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp13 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp13 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp13 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Order Book Item Grp Comp: 40 bytes                                      *)
(***************************************************************************)

OrderBookItemGrpComp ==
    [ bestBidPx     : Sample(8),
      bestBidSize   : Sample(8),
      bestOfferPx   : Sample(8),
      bestOfferSize : Sample(8),
      mdBookType    : Sample(1),
      mdSubBookType : Sample(1),
      pad6          : Sample(6) ]

EncodeOrderBookItemGrpComp(message) ==
    message.bestBidPx
        \o message.bestBidSize
        \o message.bestOfferPx
        \o message.bestOfferSize
        \o message.mdBookType
        \o message.mdSubBookType
        \o message.pad6

DecodeOrderBookItemGrpComp(bytes) ==
    LET bestBidPx == ReadBytes(bytes, 8) IN IF ~bestBidPx.ok THEN Fail ELSE
    LET bestBidSize == ReadBytes(bestBidPx.rest, 8) IN IF ~bestBidSize.ok THEN Fail ELSE
    LET bestOfferPx == ReadBytes(bestBidSize.rest, 8) IN IF ~bestOfferPx.ok THEN Fail ELSE
    LET bestOfferSize == ReadBytes(bestOfferPx.rest, 8) IN IF ~bestOfferSize.ok THEN Fail ELSE
    LET mdBookType == ReadBytes(bestOfferSize.rest, 1) IN IF ~mdBookType.ok THEN Fail ELSE
    LET mdSubBookType == ReadBytes(mdBookType.rest, 1) IN IF ~mdSubBookType.ok THEN Fail ELSE
    LET pad6 == ReadBytes(mdSubBookType.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ bestBidPx     |-> bestBidPx.value,
         bestBidSize   |-> bestBidSize.value,
         bestOfferPx   |-> bestOfferPx.value,
         bestOfferSize |-> bestOfferSize.value,
         mdBookType    |-> mdBookType.value,
         mdSubBookType |-> mdSubBookType.value,
         pad6          |-> pad6.value ], pad6.rest)

ZeroOrderBookItemGrpComp ==
    [ bestBidPx     |-> [i \in 1 .. 8 |-> 0],
      bestBidSize   |-> [i \in 1 .. 8 |-> 0],
      bestOfferPx   |-> [i \in 1 .. 8 |-> 0],
      bestOfferSize |-> [i \in 1 .. 8 |-> 0],
      mdBookType    |-> [i \in 1 .. 1 |-> 0],
      mdSubBookType |-> [i \in 1 .. 1 |-> 0],
      pad6          |-> [i \in 1 .. 6 |-> 0] ]

(* Order Book Item Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookItemGrpComp ==
    { ZeroOrderBookItemGrpComp }
        \cup { [ZeroOrderBookItemGrpComp EXCEPT !.bestBidPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookItemGrpComp EXCEPT !.bestBidSize = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookItemGrpComp EXCEPT !.bestOfferPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookItemGrpComp EXCEPT !.bestOfferSize = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookItemGrpComp EXCEPT !.mdBookType = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookItemGrpComp EXCEPT !.mdSubBookType = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookItemGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Order Book Item Grp Comp, written one after another *)
RECURSIVE EncodeOrderBookItemGrpCompList(_)
EncodeOrderBookItemGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderBookItemGrpComp(Head(messages)) \o EncodeOrderBookItemGrpCompList(Tail(messages))

(* As many Order Book Item Grp Comp as the field that counts them says *)
RECURSIVE ReadOrderBookItemGrpCompList(_, _)
ReadOrderBookItemGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderBookItemGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderBookItemGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Book Item Grp Comp of each kind, for the lists that carry them *)
OneOrderBookItemGrpComp == { ZeroOrderBookItemGrpComp }

(***************************************************************************)
(* Xetra En Light Create Deal Notification                                 *)
(***************************************************************************)

XetraEnLightCreateDealNotification ==
    [ pad2                                    : Sample(2),
      rbcHeaderComp                           : RbcHeaderComp13,
      transactTime                            : Sample(8),
      lastPx                                  : Sample(8),
      lastQty                                 : Sample(8),
      quoteId                                 : Sample(8),
      securityId                              : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      negotiationId                           : Sample(4),
      tradeId                                 : Sample(4),
      settlDate                               : Sample(4),
      tradingCapacity                         : Sample(1),
      trdRptStatus                            : Sample(1),
      messageEventSource                      : Sample(1),
      side                                    : Sample(1),
      allocMethod                             : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      rootPartyExecutingFirm                  : Sample(5),
      rootPartyExecutingTrader                : Sample(6),
      rootPartyEnteringTrader                 : Sample(6),
      targetPartyExecutingFirm                : Sample(5),
      targetPartyExecutingTrader              : Sample(6),
      firmTradeId                             : Sample(20),
      firmNegotiationId                       : Sample(20),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText4                               : Sample(16),
      pad7                                    : Sample(7),
      orderBookItemGrpComp                    : SampleLists(OneOrderBookItemGrpComp) ]

EncodeXetraEnLightCreateDealNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderComp13(message.rbcHeaderComp)
        \o message.transactTime
        \o message.lastPx
        \o message.lastQty
        \o message.quoteId
        \o message.securityId
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.negotiationId
        \o message.tradeId
        \o message.settlDate
        \o message.tradingCapacity
        \o message.trdRptStatus
        \o message.messageEventSource
        \o message.side
        \o message.allocMethod
        \o EncodeUIntBE(Len(message.orderBookItemGrpComp), 1)
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.rootPartyExecutingFirm
        \o message.rootPartyExecutingTrader
        \o message.rootPartyEnteringTrader
        \o message.targetPartyExecutingFirm
        \o message.targetPartyExecutingTrader
        \o message.firmTradeId
        \o message.firmNegotiationId
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.pad7
        \o EncodeOrderBookItemGrpCompList(message.orderBookItemGrpComp)

DecodeXetraEnLightCreateDealNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp13(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET lastPx == ReadBytes(transactTime.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET quoteId == ReadBytes(lastQty.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(securityId.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(executingTrader.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(negotiationId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET settlDate == ReadBytes(tradeId.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(settlDate.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET trdRptStatus == ReadBytes(tradingCapacity.rest, 1) IN IF ~trdRptStatus.ok THEN Fail ELSE
    LET messageEventSource == ReadBytes(trdRptStatus.rest, 1) IN IF ~messageEventSource.ok THEN Fail ELSE
    LET side == ReadBytes(messageEventSource.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET allocMethod == ReadBytes(side.rest, 1) IN IF ~allocMethod.ok THEN Fail ELSE
    LET noOrderBookItems == ReadUIntBE(allocMethod.rest, 1) IN IF ~noOrderBookItems.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(noOrderBookItems.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET rootPartyExecutingFirm == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 5) IN IF ~rootPartyExecutingFirm.ok THEN Fail ELSE
    LET rootPartyExecutingTrader == ReadBytes(rootPartyExecutingFirm.rest, 6) IN IF ~rootPartyExecutingTrader.ok THEN Fail ELSE
    LET rootPartyEnteringTrader == ReadBytes(rootPartyExecutingTrader.rest, 6) IN IF ~rootPartyEnteringTrader.ok THEN Fail ELSE
    LET targetPartyExecutingFirm == ReadBytes(rootPartyEnteringTrader.rest, 5) IN IF ~targetPartyExecutingFirm.ok THEN Fail ELSE
    LET targetPartyExecutingTrader == ReadBytes(targetPartyExecutingFirm.rest, 6) IN IF ~targetPartyExecutingTrader.ok THEN Fail ELSE
    LET firmTradeId == ReadBytes(targetPartyExecutingTrader.rest, 20) IN IF ~firmTradeId.ok THEN Fail ELSE
    LET firmNegotiationId == ReadBytes(firmTradeId.rest, 20) IN IF ~firmNegotiationId.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(firmNegotiationId.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET pad7 == ReadBytes(freeText4.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET orderBookItemGrpComp == ReadOrderBookItemGrpCompList(pad7.rest, noOrderBookItems.value) IN IF ~orderBookItemGrpComp.ok THEN Fail ELSE
    Ok([ pad2                                    |-> pad2.value,
         rbcHeaderComp                           |-> rbcHeaderComp.value,
         transactTime                            |-> transactTime.value,
         lastPx                                  |-> lastPx.value,
         lastQty                                 |-> lastQty.value,
         quoteId                                 |-> quoteId.value,
         securityId                              |-> securityId.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         negotiationId                           |-> negotiationId.value,
         tradeId                                 |-> tradeId.value,
         settlDate                               |-> settlDate.value,
         tradingCapacity                         |-> tradingCapacity.value,
         trdRptStatus                            |-> trdRptStatus.value,
         messageEventSource                      |-> messageEventSource.value,
         side                                    |-> side.value,
         allocMethod                             |-> allocMethod.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         rootPartyExecutingFirm                  |-> rootPartyExecutingFirm.value,
         rootPartyExecutingTrader                |-> rootPartyExecutingTrader.value,
         rootPartyEnteringTrader                 |-> rootPartyEnteringTrader.value,
         targetPartyExecutingFirm                |-> targetPartyExecutingFirm.value,
         targetPartyExecutingTrader              |-> targetPartyExecutingTrader.value,
         firmTradeId                             |-> firmTradeId.value,
         firmNegotiationId                       |-> firmNegotiationId.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText4                               |-> freeText4.value,
         pad7                                    |-> pad7.value,
         orderBookItemGrpComp                    |-> orderBookItemGrpComp.value ], orderBookItemGrpComp.rest)

ZeroXetraEnLightCreateDealNotification ==
    [ pad2                                    |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                           |-> ZeroRbcHeaderComp13,
      transactTime                            |-> [i \in 1 .. 8 |-> 0],
      lastPx                                  |-> [i \in 1 .. 8 |-> 0],
      lastQty                                 |-> [i \in 1 .. 8 |-> 0],
      quoteId                                 |-> [i \in 1 .. 8 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      negotiationId                           |-> [i \in 1 .. 4 |-> 0],
      tradeId                                 |-> [i \in 1 .. 4 |-> 0],
      settlDate                               |-> [i \in 1 .. 4 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      trdRptStatus                            |-> [i \in 1 .. 1 |-> 0],
      messageEventSource                      |-> [i \in 1 .. 1 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      allocMethod                             |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      rootPartyExecutingFirm                  |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingTrader                |-> [i \in 1 .. 6 |-> 0],
      rootPartyEnteringTrader                 |-> [i \in 1 .. 6 |-> 0],
      targetPartyExecutingFirm                |-> [i \in 1 .. 5 |-> 0],
      targetPartyExecutingTrader              |-> [i \in 1 .. 6 |-> 0],
      firmTradeId                             |-> [i \in 1 .. 20 |-> 0],
      firmNegotiationId                       |-> [i \in 1 .. 20 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText4                               |-> [i \in 1 .. 16 |-> 0],
      pad7                                    |-> [i \in 1 .. 7 |-> 0],
      orderBookItemGrpComp                    |-> << >> ]

(* Xetra En Light Create Deal Notification at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightCreateDealNotification ==
    { ZeroXetraEnLightCreateDealNotification }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp13 }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.trdRptStatus = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.messageEventSource = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.allocMethod = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.rootPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.rootPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.rootPartyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.targetPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.targetPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.firmTradeId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.firmNegotiationId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroXetraEnLightCreateDealNotification EXCEPT !.orderBookItemGrpComp = one] : one \in SampleLists(OneOrderBookItemGrpComp) }

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
(* Xetra En Light Deal Response: 98 bytes                                  *)
(***************************************************************************)

XetraEnLightDealResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp13,
      securityId         : Sample(8),
      quoteId            : Sample(8),
      negotiationId      : Sample(4),
      tradeId            : Sample(4),
      secondaryTradeId   : Sample(4),
      firmTradeId        : Sample(20),
      firmNegotiationId  : Sample(20),
      pad4               : Sample(4) ]

EncodeXetraEnLightDealResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp13(message.responseHeaderComp)
        \o message.securityId
        \o message.quoteId
        \o message.negotiationId
        \o message.tradeId
        \o message.secondaryTradeId
        \o message.firmTradeId
        \o message.firmNegotiationId
        \o message.pad4

DecodeXetraEnLightDealResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp13(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(responseHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(securityId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(quoteId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(negotiationId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET secondaryTradeId == ReadBytes(tradeId.rest, 4) IN IF ~secondaryTradeId.ok THEN Fail ELSE
    LET firmTradeId == ReadBytes(secondaryTradeId.rest, 20) IN IF ~firmTradeId.ok THEN Fail ELSE
    LET firmNegotiationId == ReadBytes(firmTradeId.rest, 20) IN IF ~firmNegotiationId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(firmNegotiationId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value,
         securityId         |-> securityId.value,
         quoteId            |-> quoteId.value,
         negotiationId      |-> negotiationId.value,
         tradeId            |-> tradeId.value,
         secondaryTradeId   |-> secondaryTradeId.value,
         firmTradeId        |-> firmTradeId.value,
         firmNegotiationId  |-> firmNegotiationId.value,
         pad4               |-> pad4.value ], pad4.rest)

ZeroXetraEnLightDealResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp13,
      securityId         |-> [i \in 1 .. 8 |-> 0],
      quoteId            |-> [i \in 1 .. 8 |-> 0],
      negotiationId      |-> [i \in 1 .. 4 |-> 0],
      tradeId            |-> [i \in 1 .. 4 |-> 0],
      secondaryTradeId   |-> [i \in 1 .. 4 |-> 0],
      firmTradeId        |-> [i \in 1 .. 20 |-> 0],
      firmNegotiationId  |-> [i \in 1 .. 20 |-> 0],
      pad4               |-> [i \in 1 .. 4 |-> 0] ]

(* Xetra En Light Deal Response at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightDealResponse ==
    { ZeroXetraEnLightDealResponse }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp13 }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.secondaryTradeId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.firmTradeId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.firmNegotiationId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightDealResponse EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp14 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp14(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp14(bytes) ==
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

ZeroRbcHeaderComp14 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp14 ==
    { ZeroRbcHeaderComp14 }
        \cup { [ZeroRbcHeaderComp14 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp14 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp14 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp14 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp14 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp14 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp14 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp14 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Xetra En Light Negotiation Notification: 266 bytes                      *)
(***************************************************************************)

XetraEnLightNegotiationNotification ==
    [ pad2                       : Sample(2),
      rbcHeaderComp              : RbcHeaderComp14,
      transactTime               : Sample(8),
      bidPx                      : Sample(8),
      offerPx                    : Sample(8),
      leavesQty                  : Sample(8),
      negotiationId              : Sample(4),
      numberOfRespondents        : Sample(4),
      settlDate                  : Sample(4),
      quoteStatus                : Sample(1),
      side                       : Sample(1),
      partyExecutingFirm         : Sample(5),
      partyExecutingTrader       : Sample(6),
      partyEnteringTrader        : Sample(6),
      targetPartyExecutingFirm   : Sample(5),
      targetPartyExecutingTrader : Sample(6),
      firmNegotiationId          : Sample(20),
      freeText5                  : Sample(132),
      pad6                       : Sample(6) ]

EncodeXetraEnLightNegotiationNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderComp14(message.rbcHeaderComp)
        \o message.transactTime
        \o message.bidPx
        \o message.offerPx
        \o message.leavesQty
        \o message.negotiationId
        \o message.numberOfRespondents
        \o message.settlDate
        \o message.quoteStatus
        \o message.side
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.partyEnteringTrader
        \o message.targetPartyExecutingFirm
        \o message.targetPartyExecutingTrader
        \o message.firmNegotiationId
        \o message.freeText5
        \o message.pad6

DecodeXetraEnLightNegotiationNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp14(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET bidPx == ReadBytes(transactTime.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(offerPx.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(leavesQty.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET numberOfRespondents == ReadBytes(negotiationId.rest, 4) IN IF ~numberOfRespondents.ok THEN Fail ELSE
    LET settlDate == ReadBytes(numberOfRespondents.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET quoteStatus == ReadBytes(settlDate.rest, 1) IN IF ~quoteStatus.ok THEN Fail ELSE
    LET side == ReadBytes(quoteStatus.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyExecutingTrader.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET targetPartyExecutingFirm == ReadBytes(partyEnteringTrader.rest, 5) IN IF ~targetPartyExecutingFirm.ok THEN Fail ELSE
    LET targetPartyExecutingTrader == ReadBytes(targetPartyExecutingFirm.rest, 6) IN IF ~targetPartyExecutingTrader.ok THEN Fail ELSE
    LET firmNegotiationId == ReadBytes(targetPartyExecutingTrader.rest, 20) IN IF ~firmNegotiationId.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(firmNegotiationId.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET pad6 == ReadBytes(freeText5.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                       |-> pad2.value,
         rbcHeaderComp              |-> rbcHeaderComp.value,
         transactTime               |-> transactTime.value,
         bidPx                      |-> bidPx.value,
         offerPx                    |-> offerPx.value,
         leavesQty                  |-> leavesQty.value,
         negotiationId              |-> negotiationId.value,
         numberOfRespondents        |-> numberOfRespondents.value,
         settlDate                  |-> settlDate.value,
         quoteStatus                |-> quoteStatus.value,
         side                       |-> side.value,
         partyExecutingFirm         |-> partyExecutingFirm.value,
         partyExecutingTrader       |-> partyExecutingTrader.value,
         partyEnteringTrader        |-> partyEnteringTrader.value,
         targetPartyExecutingFirm   |-> targetPartyExecutingFirm.value,
         targetPartyExecutingTrader |-> targetPartyExecutingTrader.value,
         firmNegotiationId          |-> firmNegotiationId.value,
         freeText5                  |-> freeText5.value,
         pad6                       |-> pad6.value ], pad6.rest)

ZeroXetraEnLightNegotiationNotification ==
    [ pad2                       |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp              |-> ZeroRbcHeaderComp14,
      transactTime               |-> [i \in 1 .. 8 |-> 0],
      bidPx                      |-> [i \in 1 .. 8 |-> 0],
      offerPx                    |-> [i \in 1 .. 8 |-> 0],
      leavesQty                  |-> [i \in 1 .. 8 |-> 0],
      negotiationId              |-> [i \in 1 .. 4 |-> 0],
      numberOfRespondents        |-> [i \in 1 .. 4 |-> 0],
      settlDate                  |-> [i \in 1 .. 4 |-> 0],
      quoteStatus                |-> [i \in 1 .. 1 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm         |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader       |-> [i \in 1 .. 6 |-> 0],
      partyEnteringTrader        |-> [i \in 1 .. 6 |-> 0],
      targetPartyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      targetPartyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      firmNegotiationId          |-> [i \in 1 .. 20 |-> 0],
      freeText5                  |-> [i \in 1 .. 132 |-> 0],
      pad6                       |-> [i \in 1 .. 6 |-> 0] ]

(* Xetra En Light Negotiation Notification at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightNegotiationNotification ==
    { ZeroXetraEnLightNegotiationNotification }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp14 }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.numberOfRespondents = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.quoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.targetPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.targetPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.firmNegotiationId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroXetraEnLightNegotiationNotification EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp15 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp15(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp15(bytes) ==
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

ZeroRbcHeaderComp15 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp15 ==
    { ZeroRbcHeaderComp15 }
        \cup { [ZeroRbcHeaderComp15 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp15 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp15 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp15 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp15 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp15 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp15 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp15 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Xetra En Light Target Parties Comp: 16 bytes                            *)
(***************************************************************************)

XetraEnLightTargetPartiesComp ==
    [ targetPartyIdExecutingTrader : Sample(4),
      targetPartyExecutingFirm     : Sample(5),
      targetPartyExecutingTrader   : Sample(6),
      pad1                         : Sample(1) ]

EncodeXetraEnLightTargetPartiesComp(message) ==
    message.targetPartyIdExecutingTrader
        \o message.targetPartyExecutingFirm
        \o message.targetPartyExecutingTrader
        \o message.pad1

DecodeXetraEnLightTargetPartiesComp(bytes) ==
    LET targetPartyIdExecutingTrader == ReadBytes(bytes, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET targetPartyExecutingFirm == ReadBytes(targetPartyIdExecutingTrader.rest, 5) IN IF ~targetPartyExecutingFirm.ok THEN Fail ELSE
    LET targetPartyExecutingTrader == ReadBytes(targetPartyExecutingFirm.rest, 6) IN IF ~targetPartyExecutingTrader.ok THEN Fail ELSE
    LET pad1 == ReadBytes(targetPartyExecutingTrader.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ targetPartyIdExecutingTrader |-> targetPartyIdExecutingTrader.value,
         targetPartyExecutingFirm     |-> targetPartyExecutingFirm.value,
         targetPartyExecutingTrader   |-> targetPartyExecutingTrader.value,
         pad1                         |-> pad1.value ], pad1.rest)

ZeroXetraEnLightTargetPartiesComp ==
    [ targetPartyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      targetPartyExecutingFirm     |-> [i \in 1 .. 5 |-> 0],
      targetPartyExecutingTrader   |-> [i \in 1 .. 6 |-> 0],
      pad1                         |-> [i \in 1 .. 1 |-> 0] ]

(* Xetra En Light Target Parties Comp at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightTargetPartiesComp ==
    { ZeroXetraEnLightTargetPartiesComp }
        \cup { [ZeroXetraEnLightTargetPartiesComp EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightTargetPartiesComp EXCEPT !.targetPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightTargetPartiesComp EXCEPT !.targetPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightTargetPartiesComp EXCEPT !.pad1 = one] : one \in Sample(1) }

(* A run of Xetra En Light Target Parties Comp, written one after another *)
RECURSIVE EncodeXetraEnLightTargetPartiesCompList(_)
EncodeXetraEnLightTargetPartiesCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeXetraEnLightTargetPartiesComp(Head(messages)) \o EncodeXetraEnLightTargetPartiesCompList(Tail(messages))

(* As many Xetra En Light Target Parties Comp as the field that counts them says *)
RECURSIVE ReadXetraEnLightTargetPartiesCompList(_, _)
ReadXetraEnLightTargetPartiesCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeXetraEnLightTargetPartiesComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadXetraEnLightTargetPartiesCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Xetra En Light Target Parties Comp of each kind, for the lists that carry them *)
OneXetraEnLightTargetPartiesComp == { ZeroXetraEnLightTargetPartiesComp }

(***************************************************************************)
(* Xetra En Light Negotiation Requester Notification                       *)
(***************************************************************************)

XetraEnLightNegotiationRequesterNotification ==
    [ pad2                              : Sample(2),
      rbcHeaderComp                     : RbcHeaderComp15,
      transactTime                      : Sample(8),
      trdRegTsExecutionTime             : Sample(8),
      bidPx                             : Sample(8),
      offerPx                           : Sample(8),
      orderQty                          : Sample(8),
      lastPx                            : Sample(8),
      leavesQty                         : Sample(8),
      lastQty                           : Sample(8),
      negotiationId                     : Sample(4),
      numberOfRespondents               : Sample(4),
      settlDate                         : Sample(4),
      quoteStatus                       : Sample(1),
      numberOfRespDisclosureInstruction : Sample(1),
      side                              : Sample(1),
      partyExecutingFirm                : Sample(5),
      partyExecutingTrader              : Sample(6),
      partyEnteringTrader               : Sample(6),
      firmNegotiationId                 : Sample(20),
      freeText5                         : Sample(132),
      pad7                              : Sample(7),
      xetraEnLightTargetPartiesComp     : SampleLists(OneXetraEnLightTargetPartiesComp) ]

EncodeXetraEnLightNegotiationRequesterNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderComp15(message.rbcHeaderComp)
        \o message.transactTime
        \o message.trdRegTsExecutionTime
        \o message.bidPx
        \o message.offerPx
        \o message.orderQty
        \o message.lastPx
        \o message.leavesQty
        \o message.lastQty
        \o message.negotiationId
        \o message.numberOfRespondents
        \o message.settlDate
        \o message.quoteStatus
        \o EncodeUIntBE(Len(message.xetraEnLightTargetPartiesComp), 1)
        \o message.numberOfRespDisclosureInstruction
        \o message.side
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.partyEnteringTrader
        \o message.firmNegotiationId
        \o message.freeText5
        \o message.pad7
        \o EncodeXetraEnLightTargetPartiesCompList(message.xetraEnLightTargetPartiesComp)

DecodeXetraEnLightNegotiationRequesterNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp15(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET trdRegTsExecutionTime == ReadBytes(transactTime.rest, 8) IN IF ~trdRegTsExecutionTime.ok THEN Fail ELSE
    LET bidPx == ReadBytes(trdRegTsExecutionTime.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET orderQty == ReadBytes(offerPx.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(orderQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastPx.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET lastQty == ReadBytes(leavesQty.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(lastQty.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET numberOfRespondents == ReadBytes(negotiationId.rest, 4) IN IF ~numberOfRespondents.ok THEN Fail ELSE
    LET settlDate == ReadBytes(numberOfRespondents.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET quoteStatus == ReadBytes(settlDate.rest, 1) IN IF ~quoteStatus.ok THEN Fail ELSE
    LET noTargetPartyIDs == ReadUIntBE(quoteStatus.rest, 1) IN IF ~noTargetPartyIDs.ok THEN Fail ELSE
    LET numberOfRespDisclosureInstruction == ReadBytes(noTargetPartyIDs.rest, 1) IN IF ~numberOfRespDisclosureInstruction.ok THEN Fail ELSE
    LET side == ReadBytes(numberOfRespDisclosureInstruction.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyExecutingTrader.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET firmNegotiationId == ReadBytes(partyEnteringTrader.rest, 20) IN IF ~firmNegotiationId.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(firmNegotiationId.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET pad7 == ReadBytes(freeText5.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET xetraEnLightTargetPartiesComp == ReadXetraEnLightTargetPartiesCompList(pad7.rest, noTargetPartyIDs.value) IN IF ~xetraEnLightTargetPartiesComp.ok THEN Fail ELSE
    Ok([ pad2                              |-> pad2.value,
         rbcHeaderComp                     |-> rbcHeaderComp.value,
         transactTime                      |-> transactTime.value,
         trdRegTsExecutionTime             |-> trdRegTsExecutionTime.value,
         bidPx                             |-> bidPx.value,
         offerPx                           |-> offerPx.value,
         orderQty                          |-> orderQty.value,
         lastPx                            |-> lastPx.value,
         leavesQty                         |-> leavesQty.value,
         lastQty                           |-> lastQty.value,
         negotiationId                     |-> negotiationId.value,
         numberOfRespondents               |-> numberOfRespondents.value,
         settlDate                         |-> settlDate.value,
         quoteStatus                       |-> quoteStatus.value,
         numberOfRespDisclosureInstruction |-> numberOfRespDisclosureInstruction.value,
         side                              |-> side.value,
         partyExecutingFirm                |-> partyExecutingFirm.value,
         partyExecutingTrader              |-> partyExecutingTrader.value,
         partyEnteringTrader               |-> partyEnteringTrader.value,
         firmNegotiationId                 |-> firmNegotiationId.value,
         freeText5                         |-> freeText5.value,
         pad7                              |-> pad7.value,
         xetraEnLightTargetPartiesComp     |-> xetraEnLightTargetPartiesComp.value ], xetraEnLightTargetPartiesComp.rest)

ZeroXetraEnLightNegotiationRequesterNotification ==
    [ pad2                              |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                     |-> ZeroRbcHeaderComp15,
      transactTime                      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsExecutionTime             |-> [i \in 1 .. 8 |-> 0],
      bidPx                             |-> [i \in 1 .. 8 |-> 0],
      offerPx                           |-> [i \in 1 .. 8 |-> 0],
      orderQty                          |-> [i \in 1 .. 8 |-> 0],
      lastPx                            |-> [i \in 1 .. 8 |-> 0],
      leavesQty                         |-> [i \in 1 .. 8 |-> 0],
      lastQty                           |-> [i \in 1 .. 8 |-> 0],
      negotiationId                     |-> [i \in 1 .. 4 |-> 0],
      numberOfRespondents               |-> [i \in 1 .. 4 |-> 0],
      settlDate                         |-> [i \in 1 .. 4 |-> 0],
      quoteStatus                       |-> [i \in 1 .. 1 |-> 0],
      numberOfRespDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      side                              |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader              |-> [i \in 1 .. 6 |-> 0],
      partyEnteringTrader               |-> [i \in 1 .. 6 |-> 0],
      firmNegotiationId                 |-> [i \in 1 .. 20 |-> 0],
      freeText5                         |-> [i \in 1 .. 132 |-> 0],
      pad7                              |-> [i \in 1 .. 7 |-> 0],
      xetraEnLightTargetPartiesComp     |-> << >> ]

(* Xetra En Light Negotiation Requester Notification at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightNegotiationRequesterNotification ==
    { ZeroXetraEnLightNegotiationRequesterNotification }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp15 }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.trdRegTsExecutionTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.numberOfRespondents = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.quoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.numberOfRespDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.firmNegotiationId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroXetraEnLightNegotiationRequesterNotification EXCEPT !.xetraEnLightTargetPartiesComp = one] : one \in SampleLists(OneXetraEnLightTargetPartiesComp) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp16 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp16(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp16(bytes) ==
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

ZeroRbcHeaderComp16 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp16 ==
    { ZeroRbcHeaderComp16 }
        \cup { [ZeroRbcHeaderComp16 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp16 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp16 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp16 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp16 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp16 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp16 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp16 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Xetra En Light Negotiation Status Notification: 74 bytes                *)
(***************************************************************************)

XetraEnLightNegotiationStatusNotification ==
    [ pad2              : Sample(2),
      rbcHeaderComp     : RbcHeaderComp16,
      transactTime      : Sample(8),
      negotiationId     : Sample(4),
      quoteStatus       : Sample(1),
      firmNegotiationId : Sample(20),
      pad7              : Sample(7) ]

EncodeXetraEnLightNegotiationStatusNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderComp16(message.rbcHeaderComp)
        \o message.transactTime
        \o message.negotiationId
        \o message.quoteStatus
        \o message.firmNegotiationId
        \o message.pad7

DecodeXetraEnLightNegotiationStatusNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp16(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(transactTime.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET quoteStatus == ReadBytes(negotiationId.rest, 1) IN IF ~quoteStatus.ok THEN Fail ELSE
    LET firmNegotiationId == ReadBytes(quoteStatus.rest, 20) IN IF ~firmNegotiationId.ok THEN Fail ELSE
    LET pad7 == ReadBytes(firmNegotiationId.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2              |-> pad2.value,
         rbcHeaderComp     |-> rbcHeaderComp.value,
         transactTime      |-> transactTime.value,
         negotiationId     |-> negotiationId.value,
         quoteStatus       |-> quoteStatus.value,
         firmNegotiationId |-> firmNegotiationId.value,
         pad7              |-> pad7.value ], pad7.rest)

ZeroXetraEnLightNegotiationStatusNotification ==
    [ pad2              |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp     |-> ZeroRbcHeaderComp16,
      transactTime      |-> [i \in 1 .. 8 |-> 0],
      negotiationId     |-> [i \in 1 .. 4 |-> 0],
      quoteStatus       |-> [i \in 1 .. 1 |-> 0],
      firmNegotiationId |-> [i \in 1 .. 20 |-> 0],
      pad7              |-> [i \in 1 .. 7 |-> 0] ]

(* Xetra En Light Negotiation Status Notification at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightNegotiationStatusNotification ==
    { ZeroXetraEnLightNegotiationStatusNotification }
        \cup { [ZeroXetraEnLightNegotiationStatusNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightNegotiationStatusNotification EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp16 }
        \cup { [ZeroXetraEnLightNegotiationStatusNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightNegotiationStatusNotification EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightNegotiationStatusNotification EXCEPT !.quoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightNegotiationStatusNotification EXCEPT !.firmNegotiationId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightNegotiationStatusNotification EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp17 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp17(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp17(bytes) ==
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

ZeroRbcHeaderComp17 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp17 ==
    { ZeroRbcHeaderComp17 }
        \cup { [ZeroRbcHeaderComp17 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp17 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp17 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp17 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp17 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp17 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp17 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp17 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Xetra En Light Open Negotiation Notification: 290 bytes                 *)
(***************************************************************************)

XetraEnLightOpenNegotiationNotification ==
    [ pad2                       : Sample(2),
      rbcHeaderComp              : RbcHeaderComp17,
      transactTime               : Sample(8),
      negotiationStartTime       : Sample(8),
      securityId                 : Sample(8),
      bidPx                      : Sample(8),
      offerPx                    : Sample(8),
      leavesQty                  : Sample(8),
      expireTime                 : Sample(8),
      negotiationId              : Sample(4),
      marketSegmentId            : Sample(4),
      numberOfRespondents        : Sample(4),
      settlDate                  : Sample(4),
      quoteStatus                : Sample(1),
      side                       : Sample(1),
      respondentType             : Sample(1),
      partyExecutingFirm         : Sample(5),
      partyExecutingTrader       : Sample(6),
      partyEnteringTrader        : Sample(6),
      targetPartyExecutingFirm   : Sample(5),
      targetPartyExecutingTrader : Sample(6),
      firmNegotiationId          : Sample(20),
      freeText5                  : Sample(132),
      pad1                       : Sample(1) ]

EncodeXetraEnLightOpenNegotiationNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderComp17(message.rbcHeaderComp)
        \o message.transactTime
        \o message.negotiationStartTime
        \o message.securityId
        \o message.bidPx
        \o message.offerPx
        \o message.leavesQty
        \o message.expireTime
        \o message.negotiationId
        \o message.marketSegmentId
        \o message.numberOfRespondents
        \o message.settlDate
        \o message.quoteStatus
        \o message.side
        \o message.respondentType
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.partyEnteringTrader
        \o message.targetPartyExecutingFirm
        \o message.targetPartyExecutingTrader
        \o message.firmNegotiationId
        \o message.freeText5
        \o message.pad1

DecodeXetraEnLightOpenNegotiationNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp17(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET negotiationStartTime == ReadBytes(transactTime.rest, 8) IN IF ~negotiationStartTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(negotiationStartTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(offerPx.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET expireTime == ReadBytes(leavesQty.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(expireTime.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(negotiationId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET numberOfRespondents == ReadBytes(marketSegmentId.rest, 4) IN IF ~numberOfRespondents.ok THEN Fail ELSE
    LET settlDate == ReadBytes(numberOfRespondents.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET quoteStatus == ReadBytes(settlDate.rest, 1) IN IF ~quoteStatus.ok THEN Fail ELSE
    LET side == ReadBytes(quoteStatus.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET respondentType == ReadBytes(side.rest, 1) IN IF ~respondentType.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(respondentType.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyExecutingTrader.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET targetPartyExecutingFirm == ReadBytes(partyEnteringTrader.rest, 5) IN IF ~targetPartyExecutingFirm.ok THEN Fail ELSE
    LET targetPartyExecutingTrader == ReadBytes(targetPartyExecutingFirm.rest, 6) IN IF ~targetPartyExecutingTrader.ok THEN Fail ELSE
    LET firmNegotiationId == ReadBytes(targetPartyExecutingTrader.rest, 20) IN IF ~firmNegotiationId.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(firmNegotiationId.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET pad1 == ReadBytes(freeText5.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ pad2                       |-> pad2.value,
         rbcHeaderComp              |-> rbcHeaderComp.value,
         transactTime               |-> transactTime.value,
         negotiationStartTime       |-> negotiationStartTime.value,
         securityId                 |-> securityId.value,
         bidPx                      |-> bidPx.value,
         offerPx                    |-> offerPx.value,
         leavesQty                  |-> leavesQty.value,
         expireTime                 |-> expireTime.value,
         negotiationId              |-> negotiationId.value,
         marketSegmentId            |-> marketSegmentId.value,
         numberOfRespondents        |-> numberOfRespondents.value,
         settlDate                  |-> settlDate.value,
         quoteStatus                |-> quoteStatus.value,
         side                       |-> side.value,
         respondentType             |-> respondentType.value,
         partyExecutingFirm         |-> partyExecutingFirm.value,
         partyExecutingTrader       |-> partyExecutingTrader.value,
         partyEnteringTrader        |-> partyEnteringTrader.value,
         targetPartyExecutingFirm   |-> targetPartyExecutingFirm.value,
         targetPartyExecutingTrader |-> targetPartyExecutingTrader.value,
         firmNegotiationId          |-> firmNegotiationId.value,
         freeText5                  |-> freeText5.value,
         pad1                       |-> pad1.value ], pad1.rest)

ZeroXetraEnLightOpenNegotiationNotification ==
    [ pad2                       |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp              |-> ZeroRbcHeaderComp17,
      transactTime               |-> [i \in 1 .. 8 |-> 0],
      negotiationStartTime       |-> [i \in 1 .. 8 |-> 0],
      securityId                 |-> [i \in 1 .. 8 |-> 0],
      bidPx                      |-> [i \in 1 .. 8 |-> 0],
      offerPx                    |-> [i \in 1 .. 8 |-> 0],
      leavesQty                  |-> [i \in 1 .. 8 |-> 0],
      expireTime                 |-> [i \in 1 .. 8 |-> 0],
      negotiationId              |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId            |-> [i \in 1 .. 4 |-> 0],
      numberOfRespondents        |-> [i \in 1 .. 4 |-> 0],
      settlDate                  |-> [i \in 1 .. 4 |-> 0],
      quoteStatus                |-> [i \in 1 .. 1 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      respondentType             |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm         |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader       |-> [i \in 1 .. 6 |-> 0],
      partyEnteringTrader        |-> [i \in 1 .. 6 |-> 0],
      targetPartyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      targetPartyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      firmNegotiationId          |-> [i \in 1 .. 20 |-> 0],
      freeText5                  |-> [i \in 1 .. 132 |-> 0],
      pad1                       |-> [i \in 1 .. 1 |-> 0] ]

(* Xetra En Light Open Negotiation Notification at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightOpenNegotiationNotification ==
    { ZeroXetraEnLightOpenNegotiationNotification }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp17 }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.negotiationStartTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.numberOfRespondents = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.quoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.respondentType = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.targetPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.targetPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.firmNegotiationId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroXetraEnLightOpenNegotiationNotification EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp18 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp18(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp18(bytes) ==
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

ZeroRbcHeaderComp18 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp18 ==
    { ZeroRbcHeaderComp18 }
        \cup { [ZeroRbcHeaderComp18 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp18 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp18 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp18 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp18 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp18 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp18 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp18 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Xetra En Light Target Parties Comp: 16 bytes                            *)
(***************************************************************************)

XetraEnLightTargetPartiesComp2 ==
    [ targetPartyIdExecutingTrader : Sample(4),
      targetPartyExecutingFirm     : Sample(5),
      targetPartyExecutingTrader   : Sample(6),
      pad1                         : Sample(1) ]

EncodeXetraEnLightTargetPartiesComp2(message) ==
    message.targetPartyIdExecutingTrader
        \o message.targetPartyExecutingFirm
        \o message.targetPartyExecutingTrader
        \o message.pad1

DecodeXetraEnLightTargetPartiesComp2(bytes) ==
    LET targetPartyIdExecutingTrader == ReadBytes(bytes, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET targetPartyExecutingFirm == ReadBytes(targetPartyIdExecutingTrader.rest, 5) IN IF ~targetPartyExecutingFirm.ok THEN Fail ELSE
    LET targetPartyExecutingTrader == ReadBytes(targetPartyExecutingFirm.rest, 6) IN IF ~targetPartyExecutingTrader.ok THEN Fail ELSE
    LET pad1 == ReadBytes(targetPartyExecutingTrader.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ targetPartyIdExecutingTrader |-> targetPartyIdExecutingTrader.value,
         targetPartyExecutingFirm     |-> targetPartyExecutingFirm.value,
         targetPartyExecutingTrader   |-> targetPartyExecutingTrader.value,
         pad1                         |-> pad1.value ], pad1.rest)

ZeroXetraEnLightTargetPartiesComp2 ==
    [ targetPartyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      targetPartyExecutingFirm     |-> [i \in 1 .. 5 |-> 0],
      targetPartyExecutingTrader   |-> [i \in 1 .. 6 |-> 0],
      pad1                         |-> [i \in 1 .. 1 |-> 0] ]

(* Xetra En Light Target Parties Comp at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightTargetPartiesComp2 ==
    { ZeroXetraEnLightTargetPartiesComp2 }
        \cup { [ZeroXetraEnLightTargetPartiesComp2 EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightTargetPartiesComp2 EXCEPT !.targetPartyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightTargetPartiesComp2 EXCEPT !.targetPartyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightTargetPartiesComp2 EXCEPT !.pad1 = one] : one \in Sample(1) }

(* A run of Xetra En Light Target Parties Comp, written one after another *)
RECURSIVE EncodeXetraEnLightTargetPartiesComp2List(_)
EncodeXetraEnLightTargetPartiesComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeXetraEnLightTargetPartiesComp2(Head(messages)) \o EncodeXetraEnLightTargetPartiesComp2List(Tail(messages))

(* As many Xetra En Light Target Parties Comp as the field that counts them says *)
RECURSIVE ReadXetraEnLightTargetPartiesComp2List(_, _)
ReadXetraEnLightTargetPartiesComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeXetraEnLightTargetPartiesComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadXetraEnLightTargetPartiesComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Xetra En Light Target Parties Comp of each kind, for the lists that carry them *)
OneXetraEnLightTargetPartiesComp2 == { ZeroXetraEnLightTargetPartiesComp2 }

(***************************************************************************)
(* Xetra En Light Open Negotiation Requester Notification                  *)
(***************************************************************************)

XetraEnLightOpenNegotiationRequesterNotification ==
    [ pad2                              : Sample(2),
      rbcHeaderComp                     : RbcHeaderComp18,
      transactTime                      : Sample(8),
      securityId                        : Sample(8),
      bidPx                             : Sample(8),
      offerPx                           : Sample(8),
      orderQty                          : Sample(8),
      lastPx                            : Sample(8),
      lastQty                           : Sample(8),
      expireTime                        : Sample(8),
      negotiationId                     : Sample(4),
      marketSegmentId                   : Sample(4),
      numberOfRespondents               : Sample(4),
      settlDate                         : Sample(4),
      quoteStatus                       : Sample(1),
      side                              : Sample(1),
      numberOfRespDisclosureInstruction : Sample(1),
      respondentType                    : Sample(1),
      partyExecutingFirm                : Sample(5),
      partyExecutingTrader              : Sample(6),
      partyEnteringTrader               : Sample(6),
      firmNegotiationId                 : Sample(20),
      freeText5                         : Sample(132),
      pad2v2                            : Sample(2),
      xetraEnLightTargetPartiesComp     : SampleLists(OneXetraEnLightTargetPartiesComp2) ]

EncodeXetraEnLightOpenNegotiationRequesterNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderComp18(message.rbcHeaderComp)
        \o message.transactTime
        \o message.securityId
        \o message.bidPx
        \o message.offerPx
        \o message.orderQty
        \o message.lastPx
        \o message.lastQty
        \o message.expireTime
        \o message.negotiationId
        \o message.marketSegmentId
        \o message.numberOfRespondents
        \o message.settlDate
        \o message.quoteStatus
        \o EncodeUIntBE(Len(message.xetraEnLightTargetPartiesComp), 1)
        \o message.side
        \o message.numberOfRespDisclosureInstruction
        \o message.respondentType
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.partyEnteringTrader
        \o message.firmNegotiationId
        \o message.freeText5
        \o message.pad2v2
        \o EncodeXetraEnLightTargetPartiesComp2List(message.xetraEnLightTargetPartiesComp)

DecodeXetraEnLightOpenNegotiationRequesterNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp18(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET securityId == ReadBytes(transactTime.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET orderQty == ReadBytes(offerPx.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET lastPx == ReadBytes(orderQty.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 8) IN IF ~lastQty.ok THEN Fail ELSE
    LET expireTime == ReadBytes(lastQty.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(expireTime.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(negotiationId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET numberOfRespondents == ReadBytes(marketSegmentId.rest, 4) IN IF ~numberOfRespondents.ok THEN Fail ELSE
    LET settlDate == ReadBytes(numberOfRespondents.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET quoteStatus == ReadBytes(settlDate.rest, 1) IN IF ~quoteStatus.ok THEN Fail ELSE
    LET noTargetPartyIDs == ReadUIntBE(quoteStatus.rest, 1) IN IF ~noTargetPartyIDs.ok THEN Fail ELSE
    LET side == ReadBytes(noTargetPartyIDs.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET numberOfRespDisclosureInstruction == ReadBytes(side.rest, 1) IN IF ~numberOfRespDisclosureInstruction.ok THEN Fail ELSE
    LET respondentType == ReadBytes(numberOfRespDisclosureInstruction.rest, 1) IN IF ~respondentType.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(respondentType.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyExecutingTrader.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET firmNegotiationId == ReadBytes(partyEnteringTrader.rest, 20) IN IF ~firmNegotiationId.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(firmNegotiationId.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(freeText5.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET xetraEnLightTargetPartiesComp == ReadXetraEnLightTargetPartiesComp2List(pad2v2.rest, noTargetPartyIDs.value) IN IF ~xetraEnLightTargetPartiesComp.ok THEN Fail ELSE
    Ok([ pad2                              |-> pad2.value,
         rbcHeaderComp                     |-> rbcHeaderComp.value,
         transactTime                      |-> transactTime.value,
         securityId                        |-> securityId.value,
         bidPx                             |-> bidPx.value,
         offerPx                           |-> offerPx.value,
         orderQty                          |-> orderQty.value,
         lastPx                            |-> lastPx.value,
         lastQty                           |-> lastQty.value,
         expireTime                        |-> expireTime.value,
         negotiationId                     |-> negotiationId.value,
         marketSegmentId                   |-> marketSegmentId.value,
         numberOfRespondents               |-> numberOfRespondents.value,
         settlDate                         |-> settlDate.value,
         quoteStatus                       |-> quoteStatus.value,
         side                              |-> side.value,
         numberOfRespDisclosureInstruction |-> numberOfRespDisclosureInstruction.value,
         respondentType                    |-> respondentType.value,
         partyExecutingFirm                |-> partyExecutingFirm.value,
         partyExecutingTrader              |-> partyExecutingTrader.value,
         partyEnteringTrader               |-> partyEnteringTrader.value,
         firmNegotiationId                 |-> firmNegotiationId.value,
         freeText5                         |-> freeText5.value,
         pad2v2                            |-> pad2v2.value,
         xetraEnLightTargetPartiesComp     |-> xetraEnLightTargetPartiesComp.value ], xetraEnLightTargetPartiesComp.rest)

ZeroXetraEnLightOpenNegotiationRequesterNotification ==
    [ pad2                              |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                     |-> ZeroRbcHeaderComp18,
      transactTime                      |-> [i \in 1 .. 8 |-> 0],
      securityId                        |-> [i \in 1 .. 8 |-> 0],
      bidPx                             |-> [i \in 1 .. 8 |-> 0],
      offerPx                           |-> [i \in 1 .. 8 |-> 0],
      orderQty                          |-> [i \in 1 .. 8 |-> 0],
      lastPx                            |-> [i \in 1 .. 8 |-> 0],
      lastQty                           |-> [i \in 1 .. 8 |-> 0],
      expireTime                        |-> [i \in 1 .. 8 |-> 0],
      negotiationId                     |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                   |-> [i \in 1 .. 4 |-> 0],
      numberOfRespondents               |-> [i \in 1 .. 4 |-> 0],
      settlDate                         |-> [i \in 1 .. 4 |-> 0],
      quoteStatus                       |-> [i \in 1 .. 1 |-> 0],
      side                              |-> [i \in 1 .. 1 |-> 0],
      numberOfRespDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      respondentType                    |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader              |-> [i \in 1 .. 6 |-> 0],
      partyEnteringTrader               |-> [i \in 1 .. 6 |-> 0],
      firmNegotiationId                 |-> [i \in 1 .. 20 |-> 0],
      freeText5                         |-> [i \in 1 .. 132 |-> 0],
      pad2v2                            |-> [i \in 1 .. 2 |-> 0],
      xetraEnLightTargetPartiesComp     |-> << >> ]

(* Xetra En Light Open Negotiation Requester Notification at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightOpenNegotiationRequesterNotification ==
    { ZeroXetraEnLightOpenNegotiationRequesterNotification }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp18 }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.lastQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.numberOfRespondents = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.quoteStatus = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.numberOfRespDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.respondentType = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.firmNegotiationId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequesterNotification EXCEPT !.xetraEnLightTargetPartiesComp = one] : one \in SampleLists(OneXetraEnLightTargetPartiesComp2) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp19 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp19(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp19(bytes) ==
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

ZeroRbcHeaderComp19 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp19 ==
    { ZeroRbcHeaderComp19 }
        \cup { [ZeroRbcHeaderComp19 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp19 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp19 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp19 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp19 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp19 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp19 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp19 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Xetra En Light Quote Notification: 178 bytes                            *)
(***************************************************************************)

XetraEnLightQuoteNotification ==
    [ pad2                 : Sample(2),
      rbcHeaderComp        : RbcHeaderComp19,
      transactTime         : Sample(8),
      quoteId              : Sample(8),
      secondaryQuoteId     : Sample(8),
      bidPx                : Sample(8),
      bidSize              : Sample(8),
      offerPx              : Sample(8),
      offerSize            : Sample(8),
      negotiationId        : Sample(4),
      tradingCapacity      : Sample(1),
      quotingStatus        : Sample(1),
      quoteEventReason     : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      partyEnteringTrader  : Sample(6),
      quoteReqId           : Sample(20),
      freeText1            : Sample(12),
      freeText2            : Sample(12),
      freeText4            : Sample(16),
      pad4                 : Sample(4) ]

EncodeXetraEnLightQuoteNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderComp19(message.rbcHeaderComp)
        \o message.transactTime
        \o message.quoteId
        \o message.secondaryQuoteId
        \o message.bidPx
        \o message.bidSize
        \o message.offerPx
        \o message.offerSize
        \o message.negotiationId
        \o message.tradingCapacity
        \o message.quotingStatus
        \o message.quoteEventReason
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.partyEnteringTrader
        \o message.quoteReqId
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.pad4

DecodeXetraEnLightQuoteNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp19(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET quoteId == ReadBytes(transactTime.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET secondaryQuoteId == ReadBytes(quoteId.rest, 8) IN IF ~secondaryQuoteId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(secondaryQuoteId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidSize.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPx.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(offerSize.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(negotiationId.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET quotingStatus == ReadBytes(tradingCapacity.rest, 1) IN IF ~quotingStatus.ok THEN Fail ELSE
    LET quoteEventReason == ReadBytes(quotingStatus.rest, 1) IN IF ~quoteEventReason.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(quoteEventReason.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyExecutingTrader.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(partyEnteringTrader.rest, 20) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(quoteReqId.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET pad4 == ReadBytes(freeText4.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ pad2                 |-> pad2.value,
         rbcHeaderComp        |-> rbcHeaderComp.value,
         transactTime         |-> transactTime.value,
         quoteId              |-> quoteId.value,
         secondaryQuoteId     |-> secondaryQuoteId.value,
         bidPx                |-> bidPx.value,
         bidSize              |-> bidSize.value,
         offerPx              |-> offerPx.value,
         offerSize            |-> offerSize.value,
         negotiationId        |-> negotiationId.value,
         tradingCapacity      |-> tradingCapacity.value,
         quotingStatus        |-> quotingStatus.value,
         quoteEventReason     |-> quoteEventReason.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         partyEnteringTrader  |-> partyEnteringTrader.value,
         quoteReqId           |-> quoteReqId.value,
         freeText1            |-> freeText1.value,
         freeText2            |-> freeText2.value,
         freeText4            |-> freeText4.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroXetraEnLightQuoteNotification ==
    [ pad2                 |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp        |-> ZeroRbcHeaderComp19,
      transactTime         |-> [i \in 1 .. 8 |-> 0],
      quoteId              |-> [i \in 1 .. 8 |-> 0],
      secondaryQuoteId     |-> [i \in 1 .. 8 |-> 0],
      bidPx                |-> [i \in 1 .. 8 |-> 0],
      bidSize              |-> [i \in 1 .. 8 |-> 0],
      offerPx              |-> [i \in 1 .. 8 |-> 0],
      offerSize            |-> [i \in 1 .. 8 |-> 0],
      negotiationId        |-> [i \in 1 .. 4 |-> 0],
      tradingCapacity      |-> [i \in 1 .. 1 |-> 0],
      quotingStatus        |-> [i \in 1 .. 1 |-> 0],
      quoteEventReason     |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      partyEnteringTrader  |-> [i \in 1 .. 6 |-> 0],
      quoteReqId           |-> [i \in 1 .. 20 |-> 0],
      freeText1            |-> [i \in 1 .. 12 |-> 0],
      freeText2            |-> [i \in 1 .. 12 |-> 0],
      freeText4            |-> [i \in 1 .. 16 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Xetra En Light Quote Notification at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightQuoteNotification ==
    { ZeroXetraEnLightQuoteNotification }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp19 }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.secondaryQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.quotingStatus = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.quoteEventReason = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.quoteReqId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroXetraEnLightQuoteNotification EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp20 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp20(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp20(bytes) ==
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

ZeroRbcHeaderComp20 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp20 ==
    { ZeroRbcHeaderComp20 }
        \cup { [ZeroRbcHeaderComp20 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp20 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp20 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp20 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp20 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp20 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp20 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp20 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Srqs Quote Entry Grp Comp: 80 bytes                                     *)
(***************************************************************************)

SrqsQuoteEntryGrpComp ==
    [ transactTime           : Sample(8),
      quoteId                : Sample(8),
      secondaryQuoteId       : Sample(8),
      bidPx                  : Sample(8),
      bidSize                : Sample(8),
      offerPx                : Sample(8),
      offerSize              : Sample(8),
      partyIdExecutingTrader : Sample(4),
      quotingStatus          : Sample(1),
      partyExecutingFirm     : Sample(5),
      partyExecutingTrader   : Sample(6),
      partyEnteringTrader    : Sample(6),
      pad2                   : Sample(2) ]

EncodeSrqsQuoteEntryGrpComp(message) ==
    message.transactTime
        \o message.quoteId
        \o message.secondaryQuoteId
        \o message.bidPx
        \o message.bidSize
        \o message.offerPx
        \o message.offerSize
        \o message.partyIdExecutingTrader
        \o message.quotingStatus
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.partyEnteringTrader
        \o message.pad2

DecodeSrqsQuoteEntryGrpComp(bytes) ==
    LET transactTime == ReadBytes(bytes, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET quoteId == ReadBytes(transactTime.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET secondaryQuoteId == ReadBytes(quoteId.rest, 8) IN IF ~secondaryQuoteId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(secondaryQuoteId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidSize.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPx.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET partyIdExecutingTrader == ReadBytes(offerSize.rest, 4) IN IF ~partyIdExecutingTrader.ok THEN Fail ELSE
    LET quotingStatus == ReadBytes(partyIdExecutingTrader.rest, 1) IN IF ~quotingStatus.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(quotingStatus.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET partyEnteringTrader == ReadBytes(partyExecutingTrader.rest, 6) IN IF ~partyEnteringTrader.ok THEN Fail ELSE
    LET pad2 == ReadBytes(partyEnteringTrader.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ transactTime           |-> transactTime.value,
         quoteId                |-> quoteId.value,
         secondaryQuoteId       |-> secondaryQuoteId.value,
         bidPx                  |-> bidPx.value,
         bidSize                |-> bidSize.value,
         offerPx                |-> offerPx.value,
         offerSize              |-> offerSize.value,
         partyIdExecutingTrader |-> partyIdExecutingTrader.value,
         quotingStatus          |-> quotingStatus.value,
         partyExecutingFirm     |-> partyExecutingFirm.value,
         partyExecutingTrader   |-> partyExecutingTrader.value,
         partyEnteringTrader    |-> partyEnteringTrader.value,
         pad2                   |-> pad2.value ], pad2.rest)

ZeroSrqsQuoteEntryGrpComp ==
    [ transactTime           |-> [i \in 1 .. 8 |-> 0],
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      secondaryQuoteId       |-> [i \in 1 .. 8 |-> 0],
      bidPx                  |-> [i \in 1 .. 8 |-> 0],
      bidSize                |-> [i \in 1 .. 8 |-> 0],
      offerPx                |-> [i \in 1 .. 8 |-> 0],
      offerSize              |-> [i \in 1 .. 8 |-> 0],
      partyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      quotingStatus          |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm     |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader   |-> [i \in 1 .. 6 |-> 0],
      partyEnteringTrader    |-> [i \in 1 .. 6 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0] ]

(* Srqs Quote Entry Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSrqsQuoteEntryGrpComp ==
    { ZeroSrqsQuoteEntryGrpComp }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.secondaryQuoteId = one] : one \in Sample(8) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.partyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.quotingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.partyEnteringTrader = one] : one \in Sample(6) }
        \cup { [ZeroSrqsQuoteEntryGrpComp EXCEPT !.pad2 = one] : one \in Sample(2) }

(* A run of Srqs Quote Entry Grp Comp, written one after another *)
RECURSIVE EncodeSrqsQuoteEntryGrpCompList(_)
EncodeSrqsQuoteEntryGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSrqsQuoteEntryGrpComp(Head(messages)) \o EncodeSrqsQuoteEntryGrpCompList(Tail(messages))

(* As many Srqs Quote Entry Grp Comp as the field that counts them says *)
RECURSIVE ReadSrqsQuoteEntryGrpCompList(_, _)
ReadSrqsQuoteEntryGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSrqsQuoteEntryGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSrqsQuoteEntryGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Srqs Quote Entry Grp Comp of each kind, for the lists that carry them *)
OneSrqsQuoteEntryGrpComp == { ZeroSrqsQuoteEntryGrpComp }

(***************************************************************************)
(* Xetra En Light Quote Requester Notification                             *)
(***************************************************************************)

XetraEnLightQuoteRequesterNotification ==
    [ pad2                  : Sample(2),
      rbcHeaderComp         : RbcHeaderComp20,
      transactTime          : Sample(8),
      negotiationId         : Sample(4),
      tradeId               : Sample(4),
      quoteReqId            : Sample(20),
      pad3                  : Sample(3),
      srqsQuoteEntryGrpComp : SampleLists(OneSrqsQuoteEntryGrpComp) ]

EncodeXetraEnLightQuoteRequesterNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderComp20(message.rbcHeaderComp)
        \o message.transactTime
        \o message.negotiationId
        \o message.tradeId
        \o message.quoteReqId
        \o EncodeUIntBE(Len(message.srqsQuoteEntryGrpComp), 1)
        \o message.pad3
        \o EncodeSrqsQuoteEntryGrpCompList(message.srqsQuoteEntryGrpComp)

DecodeXetraEnLightQuoteRequesterNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp20(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET transactTime == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(transactTime.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(negotiationId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(tradeId.rest, 20) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET noQuoteEntries == ReadUIntBE(quoteReqId.rest, 1) IN IF ~noQuoteEntries.ok THEN Fail ELSE
    LET pad3 == ReadBytes(noQuoteEntries.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET srqsQuoteEntryGrpComp == ReadSrqsQuoteEntryGrpCompList(pad3.rest, noQuoteEntries.value) IN IF ~srqsQuoteEntryGrpComp.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         rbcHeaderComp         |-> rbcHeaderComp.value,
         transactTime          |-> transactTime.value,
         negotiationId         |-> negotiationId.value,
         tradeId               |-> tradeId.value,
         quoteReqId            |-> quoteReqId.value,
         pad3                  |-> pad3.value,
         srqsQuoteEntryGrpComp |-> srqsQuoteEntryGrpComp.value ], srqsQuoteEntryGrpComp.rest)

ZeroXetraEnLightQuoteRequesterNotification ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp         |-> ZeroRbcHeaderComp20,
      transactTime          |-> [i \in 1 .. 8 |-> 0],
      negotiationId         |-> [i \in 1 .. 4 |-> 0],
      tradeId               |-> [i \in 1 .. 4 |-> 0],
      quoteReqId            |-> [i \in 1 .. 20 |-> 0],
      pad3                  |-> [i \in 1 .. 3 |-> 0],
      srqsQuoteEntryGrpComp |-> << >> ]

(* Xetra En Light Quote Requester Notification at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightQuoteRequesterNotification ==
    { ZeroXetraEnLightQuoteRequesterNotification }
        \cup { [ZeroXetraEnLightQuoteRequesterNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightQuoteRequesterNotification EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp20 }
        \cup { [ZeroXetraEnLightQuoteRequesterNotification EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuoteRequesterNotification EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightQuoteRequesterNotification EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightQuoteRequesterNotification EXCEPT !.quoteReqId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightQuoteRequesterNotification EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroXetraEnLightQuoteRequesterNotification EXCEPT !.srqsQuoteEntryGrpComp = one] : one \in SampleLists(OneSrqsQuoteEntryGrpComp) }

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
(* Xetra En Light Quote Response: 58 bytes                                 *)
(***************************************************************************)

XetraEnLightQuoteResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp14,
      quoteId            : Sample(8),
      negotiationId      : Sample(4),
      quoteReqId         : Sample(20) ]

EncodeXetraEnLightQuoteResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp14(message.responseHeaderComp)
        \o message.quoteId
        \o message.negotiationId
        \o message.quoteReqId

DecodeXetraEnLightQuoteResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp14(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(responseHeaderComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(quoteId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(negotiationId.rest, 20) IN IF ~quoteReqId.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value,
         quoteId            |-> quoteId.value,
         negotiationId      |-> negotiationId.value,
         quoteReqId         |-> quoteReqId.value ], quoteReqId.rest)

ZeroXetraEnLightQuoteResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp14,
      quoteId            |-> [i \in 1 .. 8 |-> 0],
      negotiationId      |-> [i \in 1 .. 4 |-> 0],
      quoteReqId         |-> [i \in 1 .. 20 |-> 0] ]

(* Xetra En Light Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightQuoteResponse ==
    { ZeroXetraEnLightQuoteResponse }
        \cup { [ZeroXetraEnLightQuoteResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightQuoteResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp14 }
        \cup { [ZeroXetraEnLightQuoteResponse EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuoteResponse EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightQuoteResponse EXCEPT !.quoteReqId = one] : one \in Sample(20) }

(***************************************************************************)
(* Rbc Header Comp: 32 bytes                                               *)
(***************************************************************************)

RbcHeaderComp21 ==
    [ sendingTime    : Sample(8),
      applSeqNum     : Sample(8),
      applSubId      : Sample(4),
      partitionId    : Sample(2),
      applResendFlag : Sample(1),
      applId         : Sample(1),
      lastFragment   : Sample(1),
      pad7           : Sample(7) ]

EncodeRbcHeaderComp21(message) ==
    message.sendingTime
        \o message.applSeqNum
        \o message.applSubId
        \o message.partitionId
        \o message.applResendFlag
        \o message.applId
        \o message.lastFragment
        \o message.pad7

DecodeRbcHeaderComp21(bytes) ==
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

ZeroRbcHeaderComp21 ==
    [ sendingTime    |-> [i \in 1 .. 8 |-> 0],
      applSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applSubId      |-> [i \in 1 .. 4 |-> 0],
      partitionId    |-> [i \in 1 .. 2 |-> 0],
      applResendFlag |-> [i \in 1 .. 1 |-> 0],
      applId         |-> [i \in 1 .. 1 |-> 0],
      lastFragment   |-> [i \in 1 .. 1 |-> 0],
      pad7           |-> [i \in 1 .. 7 |-> 0] ]

(* Rbc Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRbcHeaderComp21 ==
    { ZeroRbcHeaderComp21 }
        \cup { [ZeroRbcHeaderComp21 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp21 EXCEPT !.applSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRbcHeaderComp21 EXCEPT !.applSubId = one] : one \in Sample(4) }
        \cup { [ZeroRbcHeaderComp21 EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRbcHeaderComp21 EXCEPT !.applResendFlag = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp21 EXCEPT !.applId = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp21 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroRbcHeaderComp21 EXCEPT !.pad7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Xetra En Light Status Broadcast: 42 bytes                               *)
(***************************************************************************)

XetraEnLightStatusBroadcast ==
    [ pad2          : Sample(2),
      rbcHeaderComp : RbcHeaderComp21,
      tradeDate     : Sample(4),
      tradSesEvent  : Sample(1),
      pad3          : Sample(3) ]

EncodeXetraEnLightStatusBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp21(message.rbcHeaderComp)
        \o message.tradeDate
        \o message.tradSesEvent
        \o message.pad3

DecodeXetraEnLightStatusBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp21(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(rbcHeaderComp.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(tradeDate.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET pad3 == ReadBytes(tradSesEvent.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2          |-> pad2.value,
         rbcHeaderComp |-> rbcHeaderComp.value,
         tradeDate     |-> tradeDate.value,
         tradSesEvent  |-> tradSesEvent.value,
         pad3          |-> pad3.value ], pad3.rest)

ZeroXetraEnLightStatusBroadcast ==
    [ pad2          |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp |-> ZeroRbcHeaderComp21,
      tradeDate     |-> [i \in 1 .. 4 |-> 0],
      tradSesEvent  |-> [i \in 1 .. 1 |-> 0],
      pad3          |-> [i \in 1 .. 3 |-> 0] ]

(* Xetra En Light Status Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightStatusBroadcast ==
    { ZeroXetraEnLightStatusBroadcast }
        \cup { [ZeroXetraEnLightStatusBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightStatusBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp21 }
        \cup { [ZeroXetraEnLightStatusBroadcast EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightStatusBroadcast EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightStatusBroadcast EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Server Payload, selected by Template Id                                 *)
(***************************************************************************)

BestQuoteExecutionReportCode == 10414  \* 0x28ae
BestQuoteResponseCode == 10413  \* 0x28ad
BroadcastErrorNotificationCode == 10032  \* 0x2730
CrossRequestResponseCode == 10119  \* 0x2787
DeleteAllOrderBroadcastCode == 10122  \* 0x278a
DeleteAllOrderNrResponseCode == 10124  \* 0x278c
DeleteAllOrderQuoteEventBroadcastCode == 10308  \* 0x2844
DeleteAllOrderResponseCode == 10121  \* 0x2789
DeleteAllQuoteBroadcastCode == 10410  \* 0x28aa
DeleteAllQuoteResponseCode == 10409  \* 0x28a9
DeleteOrderBroadcastCode == 10112  \* 0x2780
DeleteOrderNrResponseCode == 10111  \* 0x277f
DeleteOrderResponseCode == 10110  \* 0x277e
ExtendedDeletionReportCode == 10128  \* 0x2790
ForcedLogoutNotificationCode == 10012  \* 0x271c
ForcedUserLogoutNotificationCode == 10043  \* 0x273b
HeartbeatNotificationCode == 10023  \* 0x2727
InquireEnrichmentRuleIdListResponseCode == 10041  \* 0x2739
InquireSessionListResponseCode == 10036  \* 0x2734
InquireUserResponseCode == 10039  \* 0x2737
IssuerNotificationCode == 10316  \* 0x284c
IssuerSecurityStateChangeResponseCode == 10315  \* 0x284b
LegalNotificationBroadcastCode == 10037  \* 0x2735
LogonResponseCode == 10001  \* 0x2711
LogoutResponseCode == 10003  \* 0x2713
MassQuoteResponseCode == 10406  \* 0x28a6
ModifyOrderNrResponseCode == 10108  \* 0x277c
ModifyOrderResponseCode == 10107  \* 0x277b
NewOrderNrResponseCode == 10102  \* 0x2776
NewOrderResponseCode == 10101  \* 0x2775
NewsBroadcastCode == 10031  \* 0x272f
OrderExecNotificationCode == 10104  \* 0x2778
OrderExecReportBroadcastCode == 10117  \* 0x2785
OrderExecResponseCode == 10103  \* 0x2777
PartyActionReportCode == 10042  \* 0x273a
PartyEntitlementsUpdateReportCode == 10034  \* 0x2732
QuoteActivationNotificationCode == 10411  \* 0x28ab
QuoteActivationResponseCode == 10404  \* 0x28a4
QuoteExecutionReportCode == 10407  \* 0x28a7
RfqBroadcastCode == 10415  \* 0x28af
RfqRejectNotificationCode == 10420  \* 0x28b4
RfqResponseCode == 10402  \* 0x28a2
RfqSpecialistBroadcastCode == 10419  \* 0x28b3
RejectCode == 10010  \* 0x271a
RetransmitMeMessageResponseCode == 10027  \* 0x272b
RetransmitResponseCode == 10009  \* 0x2719
ServiceAvailabilityBroadcastCode == 10030  \* 0x272e
ServiceAvailabilityMarketBroadcastCode == 10044  \* 0x273c
SpecialistDeleteAllOrderBroadcastCode == 10137  \* 0x2799
SpecialistInstrumentEventNotificationCode == 10319  \* 0x284f
SpecialistOrderBookNotificationCode == 10136  \* 0x2798
SpecialistRfqReplyNotificationCode == 10424  \* 0x28b8
SpecialistRfqReplyResponseCode == 10423  \* 0x28b7
SpecialistSecurityStateChangeResponseCode == 10318  \* 0x284e
SubscribeResponseCode == 10005  \* 0x2715
TesApproveBroadcastCode == 10607  \* 0x296f
TesBroadcastCode == 10604  \* 0x296c
TesDeleteBroadcastCode == 10606  \* 0x296e
TesExecutionBroadcastCode == 10610  \* 0x2972
TesResponseCode == 10611  \* 0x2973
TesTradeBroadcastCode == 10614  \* 0x2976
TesTradingSessionStatusBroadcastCode == 10615  \* 0x2977
TmTradingSessionStatusBroadcastCode == 10501  \* 0x2905
ThrottleUpdateNotificationCode == 10028  \* 0x272c
TradeBroadcastCode == 10500  \* 0x2904
TradingSessionStatusBroadcastCode == 10307  \* 0x2843
TrailingStopUpdateNotificationCode == 10127  \* 0x278f
UnsubscribeResponseCode == 10007  \* 0x2717
UserLoginResponseCode == 10019  \* 0x2723
UserLogoutResponseCode == 10024  \* 0x2728
XetraEnLightCreateDealNotificationCode == 10808  \* 0x2a38
XetraEnLightDealResponseCode == 10805  \* 0x2a35
XetraEnLightNegotiationNotificationCode == 10813  \* 0x2a3d
XetraEnLightNegotiationRequesterNotificationCode == 10812  \* 0x2a3c
XetraEnLightNegotiationStatusNotificationCode == 10815  \* 0x2a3f
XetraEnLightOpenNegotiationNotificationCode == 10811  \* 0x2a3b
XetraEnLightOpenNegotiationRequesterNotificationCode == 10810  \* 0x2a3a
XetraEnLightQuoteNotificationCode == 10807  \* 0x2a37
XetraEnLightQuoteRequesterNotificationCode == 10816  \* 0x2a40
XetraEnLightQuoteResponseCode == 10803  \* 0x2a33
XetraEnLightStatusBroadcastCode == 10814  \* 0x2a3e

ServerPayload ==
    [ tag : {BestQuoteExecutionReportCode}, body : BestQuoteExecutionReport ]
        \cup [ tag : {BestQuoteResponseCode}, body : BestQuoteResponse ]
        \cup [ tag : {BroadcastErrorNotificationCode}, body : BroadcastErrorNotification ]
        \cup [ tag : {CrossRequestResponseCode}, body : CrossRequestResponse ]
        \cup [ tag : {DeleteAllOrderBroadcastCode}, body : DeleteAllOrderBroadcast ]
        \cup [ tag : {DeleteAllOrderNrResponseCode}, body : DeleteAllOrderNrResponse ]
        \cup [ tag : {DeleteAllOrderQuoteEventBroadcastCode}, body : DeleteAllOrderQuoteEventBroadcast ]
        \cup [ tag : {DeleteAllOrderResponseCode}, body : DeleteAllOrderResponse ]
        \cup [ tag : {DeleteAllQuoteBroadcastCode}, body : DeleteAllQuoteBroadcast ]
        \cup [ tag : {DeleteAllQuoteResponseCode}, body : DeleteAllQuoteResponse ]
        \cup [ tag : {DeleteOrderBroadcastCode}, body : DeleteOrderBroadcast ]
        \cup [ tag : {DeleteOrderNrResponseCode}, body : DeleteOrderNrResponse ]
        \cup [ tag : {DeleteOrderResponseCode}, body : DeleteOrderResponse ]
        \cup [ tag : {ExtendedDeletionReportCode}, body : ExtendedDeletionReport ]
        \cup [ tag : {ForcedLogoutNotificationCode}, body : ForcedLogoutNotification ]
        \cup [ tag : {ForcedUserLogoutNotificationCode}, body : ForcedUserLogoutNotification ]
        \cup [ tag : {HeartbeatNotificationCode}, body : HeartbeatNotification ]
        \cup [ tag : {InquireEnrichmentRuleIdListResponseCode}, body : InquireEnrichmentRuleIdListResponse ]
        \cup [ tag : {InquireSessionListResponseCode}, body : InquireSessionListResponse ]
        \cup [ tag : {InquireUserResponseCode}, body : InquireUserResponse ]
        \cup [ tag : {IssuerNotificationCode}, body : IssuerNotification ]
        \cup [ tag : {IssuerSecurityStateChangeResponseCode}, body : IssuerSecurityStateChangeResponse ]
        \cup [ tag : {LegalNotificationBroadcastCode}, body : LegalNotificationBroadcast ]
        \cup [ tag : {LogonResponseCode}, body : LogonResponse ]
        \cup [ tag : {LogoutResponseCode}, body : LogoutResponse ]
        \cup [ tag : {MassQuoteResponseCode}, body : MassQuoteResponse ]
        \cup [ tag : {ModifyOrderNrResponseCode}, body : ModifyOrderNrResponse ]
        \cup [ tag : {ModifyOrderResponseCode}, body : ModifyOrderResponse ]
        \cup [ tag : {NewOrderNrResponseCode}, body : NewOrderNrResponse ]
        \cup [ tag : {NewOrderResponseCode}, body : NewOrderResponse ]
        \cup [ tag : {NewsBroadcastCode}, body : NewsBroadcast ]
        \cup [ tag : {OrderExecNotificationCode}, body : OrderExecNotification ]
        \cup [ tag : {OrderExecReportBroadcastCode}, body : OrderExecReportBroadcast ]
        \cup [ tag : {OrderExecResponseCode}, body : OrderExecResponse ]
        \cup [ tag : {PartyActionReportCode}, body : PartyActionReport ]
        \cup [ tag : {PartyEntitlementsUpdateReportCode}, body : PartyEntitlementsUpdateReport ]
        \cup [ tag : {QuoteActivationNotificationCode}, body : QuoteActivationNotification ]
        \cup [ tag : {QuoteActivationResponseCode}, body : QuoteActivationResponse ]
        \cup [ tag : {QuoteExecutionReportCode}, body : QuoteExecutionReport ]
        \cup [ tag : {RfqBroadcastCode}, body : RfqBroadcast ]
        \cup [ tag : {RfqRejectNotificationCode}, body : RfqRejectNotification ]
        \cup [ tag : {RfqResponseCode}, body : RfqResponse ]
        \cup [ tag : {RfqSpecialistBroadcastCode}, body : RfqSpecialistBroadcast ]
        \cup [ tag : {RejectCode}, body : Reject ]
        \cup [ tag : {RetransmitMeMessageResponseCode}, body : RetransmitMeMessageResponse ]
        \cup [ tag : {RetransmitResponseCode}, body : RetransmitResponse ]
        \cup [ tag : {ServiceAvailabilityBroadcastCode}, body : ServiceAvailabilityBroadcast ]
        \cup [ tag : {ServiceAvailabilityMarketBroadcastCode}, body : ServiceAvailabilityMarketBroadcast ]
        \cup [ tag : {SpecialistDeleteAllOrderBroadcastCode}, body : SpecialistDeleteAllOrderBroadcast ]
        \cup [ tag : {SpecialistInstrumentEventNotificationCode}, body : SpecialistInstrumentEventNotification ]
        \cup [ tag : {SpecialistOrderBookNotificationCode}, body : SpecialistOrderBookNotification ]
        \cup [ tag : {SpecialistRfqReplyNotificationCode}, body : SpecialistRfqReplyNotification ]
        \cup [ tag : {SpecialistRfqReplyResponseCode}, body : SpecialistRfqReplyResponse ]
        \cup [ tag : {SpecialistSecurityStateChangeResponseCode}, body : SpecialistSecurityStateChangeResponse ]
        \cup [ tag : {SubscribeResponseCode}, body : SubscribeResponse ]
        \cup [ tag : {TesApproveBroadcastCode}, body : TesApproveBroadcast ]
        \cup [ tag : {TesBroadcastCode}, body : TesBroadcast ]
        \cup [ tag : {TesDeleteBroadcastCode}, body : TesDeleteBroadcast ]
        \cup [ tag : {TesExecutionBroadcastCode}, body : TesExecutionBroadcast ]
        \cup [ tag : {TesResponseCode}, body : TesResponse ]
        \cup [ tag : {TesTradeBroadcastCode}, body : TesTradeBroadcast ]
        \cup [ tag : {TesTradingSessionStatusBroadcastCode}, body : TesTradingSessionStatusBroadcast ]
        \cup [ tag : {TmTradingSessionStatusBroadcastCode}, body : TmTradingSessionStatusBroadcast ]
        \cup [ tag : {ThrottleUpdateNotificationCode}, body : ThrottleUpdateNotification ]
        \cup [ tag : {TradeBroadcastCode}, body : TradeBroadcast ]
        \cup [ tag : {TradingSessionStatusBroadcastCode}, body : TradingSessionStatusBroadcast ]
        \cup [ tag : {TrailingStopUpdateNotificationCode}, body : TrailingStopUpdateNotification ]
        \cup [ tag : {UnsubscribeResponseCode}, body : UnsubscribeResponse ]
        \cup [ tag : {UserLoginResponseCode}, body : UserLoginResponse ]
        \cup [ tag : {UserLogoutResponseCode}, body : UserLogoutResponse ]
        \cup [ tag : {XetraEnLightCreateDealNotificationCode}, body : XetraEnLightCreateDealNotification ]
        \cup [ tag : {XetraEnLightDealResponseCode}, body : XetraEnLightDealResponse ]
        \cup [ tag : {XetraEnLightNegotiationNotificationCode}, body : XetraEnLightNegotiationNotification ]
        \cup [ tag : {XetraEnLightNegotiationRequesterNotificationCode}, body : XetraEnLightNegotiationRequesterNotification ]
        \cup [ tag : {XetraEnLightNegotiationStatusNotificationCode}, body : XetraEnLightNegotiationStatusNotification ]
        \cup [ tag : {XetraEnLightOpenNegotiationNotificationCode}, body : XetraEnLightOpenNegotiationNotification ]
        \cup [ tag : {XetraEnLightOpenNegotiationRequesterNotificationCode}, body : XetraEnLightOpenNegotiationRequesterNotification ]
        \cup [ tag : {XetraEnLightQuoteNotificationCode}, body : XetraEnLightQuoteNotification ]
        \cup [ tag : {XetraEnLightQuoteRequesterNotificationCode}, body : XetraEnLightQuoteRequesterNotification ]
        \cup [ tag : {XetraEnLightQuoteResponseCode}, body : XetraEnLightQuoteResponse ]
        \cup [ tag : {XetraEnLightStatusBroadcastCode}, body : XetraEnLightStatusBroadcast ]

EncodeServerPayload(message) ==
    CASE message.tag = BestQuoteExecutionReportCode -> EncodeBestQuoteExecutionReport(message.body)
      [] message.tag = BestQuoteResponseCode -> EncodeBestQuoteResponse(message.body)
      [] message.tag = BroadcastErrorNotificationCode -> EncodeBroadcastErrorNotification(message.body)
      [] message.tag = CrossRequestResponseCode -> EncodeCrossRequestResponse(message.body)
      [] message.tag = DeleteAllOrderBroadcastCode -> EncodeDeleteAllOrderBroadcast(message.body)
      [] message.tag = DeleteAllOrderNrResponseCode -> EncodeDeleteAllOrderNrResponse(message.body)
      [] message.tag = DeleteAllOrderQuoteEventBroadcastCode -> EncodeDeleteAllOrderQuoteEventBroadcast(message.body)
      [] message.tag = DeleteAllOrderResponseCode -> EncodeDeleteAllOrderResponse(message.body)
      [] message.tag = DeleteAllQuoteBroadcastCode -> EncodeDeleteAllQuoteBroadcast(message.body)
      [] message.tag = DeleteAllQuoteResponseCode -> EncodeDeleteAllQuoteResponse(message.body)
      [] message.tag = DeleteOrderBroadcastCode -> EncodeDeleteOrderBroadcast(message.body)
      [] message.tag = DeleteOrderNrResponseCode -> EncodeDeleteOrderNrResponse(message.body)
      [] message.tag = DeleteOrderResponseCode -> EncodeDeleteOrderResponse(message.body)
      [] message.tag = ExtendedDeletionReportCode -> EncodeExtendedDeletionReport(message.body)
      [] message.tag = ForcedLogoutNotificationCode -> EncodeForcedLogoutNotification(message.body)
      [] message.tag = ForcedUserLogoutNotificationCode -> EncodeForcedUserLogoutNotification(message.body)
      [] message.tag = HeartbeatNotificationCode -> EncodeHeartbeatNotification(message.body)
      [] message.tag = InquireEnrichmentRuleIdListResponseCode -> EncodeInquireEnrichmentRuleIdListResponse(message.body)
      [] message.tag = InquireSessionListResponseCode -> EncodeInquireSessionListResponse(message.body)
      [] message.tag = InquireUserResponseCode -> EncodeInquireUserResponse(message.body)
      [] message.tag = IssuerNotificationCode -> EncodeIssuerNotification(message.body)
      [] message.tag = IssuerSecurityStateChangeResponseCode -> EncodeIssuerSecurityStateChangeResponse(message.body)
      [] message.tag = LegalNotificationBroadcastCode -> EncodeLegalNotificationBroadcast(message.body)
      [] message.tag = LogonResponseCode -> EncodeLogonResponse(message.body)
      [] message.tag = LogoutResponseCode -> EncodeLogoutResponse(message.body)
      [] message.tag = MassQuoteResponseCode -> EncodeMassQuoteResponse(message.body)
      [] message.tag = ModifyOrderNrResponseCode -> EncodeModifyOrderNrResponse(message.body)
      [] message.tag = ModifyOrderResponseCode -> EncodeModifyOrderResponse(message.body)
      [] message.tag = NewOrderNrResponseCode -> EncodeNewOrderNrResponse(message.body)
      [] message.tag = NewOrderResponseCode -> EncodeNewOrderResponse(message.body)
      [] message.tag = NewsBroadcastCode -> EncodeNewsBroadcast(message.body)
      [] message.tag = OrderExecNotificationCode -> EncodeOrderExecNotification(message.body)
      [] message.tag = OrderExecReportBroadcastCode -> EncodeOrderExecReportBroadcast(message.body)
      [] message.tag = OrderExecResponseCode -> EncodeOrderExecResponse(message.body)
      [] message.tag = PartyActionReportCode -> EncodePartyActionReport(message.body)
      [] message.tag = PartyEntitlementsUpdateReportCode -> EncodePartyEntitlementsUpdateReport(message.body)
      [] message.tag = QuoteActivationNotificationCode -> EncodeQuoteActivationNotification(message.body)
      [] message.tag = QuoteActivationResponseCode -> EncodeQuoteActivationResponse(message.body)
      [] message.tag = QuoteExecutionReportCode -> EncodeQuoteExecutionReport(message.body)
      [] message.tag = RfqBroadcastCode -> EncodeRfqBroadcast(message.body)
      [] message.tag = RfqRejectNotificationCode -> EncodeRfqRejectNotification(message.body)
      [] message.tag = RfqResponseCode -> EncodeRfqResponse(message.body)
      [] message.tag = RfqSpecialistBroadcastCode -> EncodeRfqSpecialistBroadcast(message.body)
      [] message.tag = RejectCode -> EncodeReject(message.body)
      [] message.tag = RetransmitMeMessageResponseCode -> EncodeRetransmitMeMessageResponse(message.body)
      [] message.tag = RetransmitResponseCode -> EncodeRetransmitResponse(message.body)
      [] message.tag = ServiceAvailabilityBroadcastCode -> EncodeServiceAvailabilityBroadcast(message.body)
      [] message.tag = ServiceAvailabilityMarketBroadcastCode -> EncodeServiceAvailabilityMarketBroadcast(message.body)
      [] message.tag = SpecialistDeleteAllOrderBroadcastCode -> EncodeSpecialistDeleteAllOrderBroadcast(message.body)
      [] message.tag = SpecialistInstrumentEventNotificationCode -> EncodeSpecialistInstrumentEventNotification(message.body)
      [] message.tag = SpecialistOrderBookNotificationCode -> EncodeSpecialistOrderBookNotification(message.body)
      [] message.tag = SpecialistRfqReplyNotificationCode -> EncodeSpecialistRfqReplyNotification(message.body)
      [] message.tag = SpecialistRfqReplyResponseCode -> EncodeSpecialistRfqReplyResponse(message.body)
      [] message.tag = SpecialistSecurityStateChangeResponseCode -> EncodeSpecialistSecurityStateChangeResponse(message.body)
      [] message.tag = SubscribeResponseCode -> EncodeSubscribeResponse(message.body)
      [] message.tag = TesApproveBroadcastCode -> EncodeTesApproveBroadcast(message.body)
      [] message.tag = TesBroadcastCode -> EncodeTesBroadcast(message.body)
      [] message.tag = TesDeleteBroadcastCode -> EncodeTesDeleteBroadcast(message.body)
      [] message.tag = TesExecutionBroadcastCode -> EncodeTesExecutionBroadcast(message.body)
      [] message.tag = TesResponseCode -> EncodeTesResponse(message.body)
      [] message.tag = TesTradeBroadcastCode -> EncodeTesTradeBroadcast(message.body)
      [] message.tag = TesTradingSessionStatusBroadcastCode -> EncodeTesTradingSessionStatusBroadcast(message.body)
      [] message.tag = TmTradingSessionStatusBroadcastCode -> EncodeTmTradingSessionStatusBroadcast(message.body)
      [] message.tag = ThrottleUpdateNotificationCode -> EncodeThrottleUpdateNotification(message.body)
      [] message.tag = TradeBroadcastCode -> EncodeTradeBroadcast(message.body)
      [] message.tag = TradingSessionStatusBroadcastCode -> EncodeTradingSessionStatusBroadcast(message.body)
      [] message.tag = TrailingStopUpdateNotificationCode -> EncodeTrailingStopUpdateNotification(message.body)
      [] message.tag = UnsubscribeResponseCode -> EncodeUnsubscribeResponse(message.body)
      [] message.tag = UserLoginResponseCode -> EncodeUserLoginResponse(message.body)
      [] message.tag = UserLogoutResponseCode -> EncodeUserLogoutResponse(message.body)
      [] message.tag = XetraEnLightCreateDealNotificationCode -> EncodeXetraEnLightCreateDealNotification(message.body)
      [] message.tag = XetraEnLightDealResponseCode -> EncodeXetraEnLightDealResponse(message.body)
      [] message.tag = XetraEnLightNegotiationNotificationCode -> EncodeXetraEnLightNegotiationNotification(message.body)
      [] message.tag = XetraEnLightNegotiationRequesterNotificationCode -> EncodeXetraEnLightNegotiationRequesterNotification(message.body)
      [] message.tag = XetraEnLightNegotiationStatusNotificationCode -> EncodeXetraEnLightNegotiationStatusNotification(message.body)
      [] message.tag = XetraEnLightOpenNegotiationNotificationCode -> EncodeXetraEnLightOpenNegotiationNotification(message.body)
      [] message.tag = XetraEnLightOpenNegotiationRequesterNotificationCode -> EncodeXetraEnLightOpenNegotiationRequesterNotification(message.body)
      [] message.tag = XetraEnLightQuoteNotificationCode -> EncodeXetraEnLightQuoteNotification(message.body)
      [] message.tag = XetraEnLightQuoteRequesterNotificationCode -> EncodeXetraEnLightQuoteRequesterNotification(message.body)
      [] message.tag = XetraEnLightQuoteResponseCode -> EncodeXetraEnLightQuoteResponse(message.body)
      [] message.tag = XetraEnLightStatusBroadcastCode -> EncodeXetraEnLightStatusBroadcast(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = BestQuoteExecutionReportCode -> DecodeBestQuoteExecutionReport(bytes)
              [] tag = BestQuoteResponseCode -> DecodeBestQuoteResponse(bytes)
              [] tag = BroadcastErrorNotificationCode -> DecodeBroadcastErrorNotification(bytes)
              [] tag = CrossRequestResponseCode -> DecodeCrossRequestResponse(bytes)
              [] tag = DeleteAllOrderBroadcastCode -> DecodeDeleteAllOrderBroadcast(bytes)
              [] tag = DeleteAllOrderNrResponseCode -> DecodeDeleteAllOrderNrResponse(bytes)
              [] tag = DeleteAllOrderQuoteEventBroadcastCode -> DecodeDeleteAllOrderQuoteEventBroadcast(bytes)
              [] tag = DeleteAllOrderResponseCode -> DecodeDeleteAllOrderResponse(bytes)
              [] tag = DeleteAllQuoteBroadcastCode -> DecodeDeleteAllQuoteBroadcast(bytes)
              [] tag = DeleteAllQuoteResponseCode -> DecodeDeleteAllQuoteResponse(bytes)
              [] tag = DeleteOrderBroadcastCode -> DecodeDeleteOrderBroadcast(bytes)
              [] tag = DeleteOrderNrResponseCode -> DecodeDeleteOrderNrResponse(bytes)
              [] tag = DeleteOrderResponseCode -> DecodeDeleteOrderResponse(bytes)
              [] tag = ExtendedDeletionReportCode -> DecodeExtendedDeletionReport(bytes)
              [] tag = ForcedLogoutNotificationCode -> DecodeForcedLogoutNotification(bytes)
              [] tag = ForcedUserLogoutNotificationCode -> DecodeForcedUserLogoutNotification(bytes)
              [] tag = HeartbeatNotificationCode -> DecodeHeartbeatNotification(bytes)
              [] tag = InquireEnrichmentRuleIdListResponseCode -> DecodeInquireEnrichmentRuleIdListResponse(bytes)
              [] tag = InquireSessionListResponseCode -> DecodeInquireSessionListResponse(bytes)
              [] tag = InquireUserResponseCode -> DecodeInquireUserResponse(bytes)
              [] tag = IssuerNotificationCode -> DecodeIssuerNotification(bytes)
              [] tag = IssuerSecurityStateChangeResponseCode -> DecodeIssuerSecurityStateChangeResponse(bytes)
              [] tag = LegalNotificationBroadcastCode -> DecodeLegalNotificationBroadcast(bytes)
              [] tag = LogonResponseCode -> DecodeLogonResponse(bytes)
              [] tag = LogoutResponseCode -> DecodeLogoutResponse(bytes)
              [] tag = MassQuoteResponseCode -> DecodeMassQuoteResponse(bytes)
              [] tag = ModifyOrderNrResponseCode -> DecodeModifyOrderNrResponse(bytes)
              [] tag = ModifyOrderResponseCode -> DecodeModifyOrderResponse(bytes)
              [] tag = NewOrderNrResponseCode -> DecodeNewOrderNrResponse(bytes)
              [] tag = NewOrderResponseCode -> DecodeNewOrderResponse(bytes)
              [] tag = NewsBroadcastCode -> DecodeNewsBroadcast(bytes)
              [] tag = OrderExecNotificationCode -> DecodeOrderExecNotification(bytes)
              [] tag = OrderExecReportBroadcastCode -> DecodeOrderExecReportBroadcast(bytes)
              [] tag = OrderExecResponseCode -> DecodeOrderExecResponse(bytes)
              [] tag = PartyActionReportCode -> DecodePartyActionReport(bytes)
              [] tag = PartyEntitlementsUpdateReportCode -> DecodePartyEntitlementsUpdateReport(bytes)
              [] tag = QuoteActivationNotificationCode -> DecodeQuoteActivationNotification(bytes)
              [] tag = QuoteActivationResponseCode -> DecodeQuoteActivationResponse(bytes)
              [] tag = QuoteExecutionReportCode -> DecodeQuoteExecutionReport(bytes)
              [] tag = RfqBroadcastCode -> DecodeRfqBroadcast(bytes)
              [] tag = RfqRejectNotificationCode -> DecodeRfqRejectNotification(bytes)
              [] tag = RfqResponseCode -> DecodeRfqResponse(bytes)
              [] tag = RfqSpecialistBroadcastCode -> DecodeRfqSpecialistBroadcast(bytes)
              [] tag = RejectCode -> DecodeReject(bytes)
              [] tag = RetransmitMeMessageResponseCode -> DecodeRetransmitMeMessageResponse(bytes)
              [] tag = RetransmitResponseCode -> DecodeRetransmitResponse(bytes)
              [] tag = ServiceAvailabilityBroadcastCode -> DecodeServiceAvailabilityBroadcast(bytes)
              [] tag = ServiceAvailabilityMarketBroadcastCode -> DecodeServiceAvailabilityMarketBroadcast(bytes)
              [] tag = SpecialistDeleteAllOrderBroadcastCode -> DecodeSpecialistDeleteAllOrderBroadcast(bytes)
              [] tag = SpecialistInstrumentEventNotificationCode -> DecodeSpecialistInstrumentEventNotification(bytes)
              [] tag = SpecialistOrderBookNotificationCode -> DecodeSpecialistOrderBookNotification(bytes)
              [] tag = SpecialistRfqReplyNotificationCode -> DecodeSpecialistRfqReplyNotification(bytes)
              [] tag = SpecialistRfqReplyResponseCode -> DecodeSpecialistRfqReplyResponse(bytes)
              [] tag = SpecialistSecurityStateChangeResponseCode -> DecodeSpecialistSecurityStateChangeResponse(bytes)
              [] tag = SubscribeResponseCode -> DecodeSubscribeResponse(bytes)
              [] tag = TesApproveBroadcastCode -> DecodeTesApproveBroadcast(bytes)
              [] tag = TesBroadcastCode -> DecodeTesBroadcast(bytes)
              [] tag = TesDeleteBroadcastCode -> DecodeTesDeleteBroadcast(bytes)
              [] tag = TesExecutionBroadcastCode -> DecodeTesExecutionBroadcast(bytes)
              [] tag = TesResponseCode -> DecodeTesResponse(bytes)
              [] tag = TesTradeBroadcastCode -> DecodeTesTradeBroadcast(bytes)
              [] tag = TesTradingSessionStatusBroadcastCode -> DecodeTesTradingSessionStatusBroadcast(bytes)
              [] tag = TmTradingSessionStatusBroadcastCode -> DecodeTmTradingSessionStatusBroadcast(bytes)
              [] tag = ThrottleUpdateNotificationCode -> DecodeThrottleUpdateNotification(bytes)
              [] tag = TradeBroadcastCode -> DecodeTradeBroadcast(bytes)
              [] tag = TradingSessionStatusBroadcastCode -> DecodeTradingSessionStatusBroadcast(bytes)
              [] tag = TrailingStopUpdateNotificationCode -> DecodeTrailingStopUpdateNotification(bytes)
              [] tag = UnsubscribeResponseCode -> DecodeUnsubscribeResponse(bytes)
              [] tag = UserLoginResponseCode -> DecodeUserLoginResponse(bytes)
              [] tag = UserLogoutResponseCode -> DecodeUserLogoutResponse(bytes)
              [] tag = XetraEnLightCreateDealNotificationCode -> DecodeXetraEnLightCreateDealNotification(bytes)
              [] tag = XetraEnLightDealResponseCode -> DecodeXetraEnLightDealResponse(bytes)
              [] tag = XetraEnLightNegotiationNotificationCode -> DecodeXetraEnLightNegotiationNotification(bytes)
              [] tag = XetraEnLightNegotiationRequesterNotificationCode -> DecodeXetraEnLightNegotiationRequesterNotification(bytes)
              [] tag = XetraEnLightNegotiationStatusNotificationCode -> DecodeXetraEnLightNegotiationStatusNotification(bytes)
              [] tag = XetraEnLightOpenNegotiationNotificationCode -> DecodeXetraEnLightOpenNegotiationNotification(bytes)
              [] tag = XetraEnLightOpenNegotiationRequesterNotificationCode -> DecodeXetraEnLightOpenNegotiationRequesterNotification(bytes)
              [] tag = XetraEnLightQuoteNotificationCode -> DecodeXetraEnLightQuoteNotification(bytes)
              [] tag = XetraEnLightQuoteRequesterNotificationCode -> DecodeXetraEnLightQuoteRequesterNotification(bytes)
              [] tag = XetraEnLightQuoteResponseCode -> DecodeXetraEnLightQuoteResponse(bytes)
              [] tag = XetraEnLightStatusBroadcastCode -> DecodeXetraEnLightStatusBroadcast(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> BestQuoteExecutionReportCode, body |-> ZeroBestQuoteExecutionReport]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> BestQuoteExecutionReportCode, body |-> one] : one \in CheckedBestQuoteExecutionReport }
        \cup { [tag |-> BestQuoteResponseCode, body |-> one] : one \in CheckedBestQuoteResponse }
        \cup { [tag |-> BroadcastErrorNotificationCode, body |-> one] : one \in CheckedBroadcastErrorNotification }
        \cup { [tag |-> CrossRequestResponseCode, body |-> one] : one \in CheckedCrossRequestResponse }
        \cup { [tag |-> DeleteAllOrderBroadcastCode, body |-> one] : one \in CheckedDeleteAllOrderBroadcast }
        \cup { [tag |-> DeleteAllOrderNrResponseCode, body |-> one] : one \in CheckedDeleteAllOrderNrResponse }
        \cup { [tag |-> DeleteAllOrderQuoteEventBroadcastCode, body |-> one] : one \in CheckedDeleteAllOrderQuoteEventBroadcast }
        \cup { [tag |-> DeleteAllOrderResponseCode, body |-> one] : one \in CheckedDeleteAllOrderResponse }
        \cup { [tag |-> DeleteAllQuoteBroadcastCode, body |-> one] : one \in CheckedDeleteAllQuoteBroadcast }
        \cup { [tag |-> DeleteAllQuoteResponseCode, body |-> one] : one \in CheckedDeleteAllQuoteResponse }
        \cup { [tag |-> DeleteOrderBroadcastCode, body |-> one] : one \in CheckedDeleteOrderBroadcast }
        \cup { [tag |-> DeleteOrderNrResponseCode, body |-> one] : one \in CheckedDeleteOrderNrResponse }
        \cup { [tag |-> DeleteOrderResponseCode, body |-> one] : one \in CheckedDeleteOrderResponse }
        \cup { [tag |-> ExtendedDeletionReportCode, body |-> one] : one \in CheckedExtendedDeletionReport }
        \cup { [tag |-> ForcedLogoutNotificationCode, body |-> one] : one \in CheckedForcedLogoutNotification }
        \cup { [tag |-> ForcedUserLogoutNotificationCode, body |-> one] : one \in CheckedForcedUserLogoutNotification }
        \cup { [tag |-> HeartbeatNotificationCode, body |-> one] : one \in CheckedHeartbeatNotification }
        \cup { [tag |-> InquireEnrichmentRuleIdListResponseCode, body |-> one] : one \in CheckedInquireEnrichmentRuleIdListResponse }
        \cup { [tag |-> InquireSessionListResponseCode, body |-> one] : one \in CheckedInquireSessionListResponse }
        \cup { [tag |-> InquireUserResponseCode, body |-> one] : one \in CheckedInquireUserResponse }
        \cup { [tag |-> IssuerNotificationCode, body |-> one] : one \in CheckedIssuerNotification }
        \cup { [tag |-> IssuerSecurityStateChangeResponseCode, body |-> one] : one \in CheckedIssuerSecurityStateChangeResponse }
        \cup { [tag |-> LegalNotificationBroadcastCode, body |-> one] : one \in CheckedLegalNotificationBroadcast }
        \cup { [tag |-> LogonResponseCode, body |-> one] : one \in CheckedLogonResponse }
        \cup { [tag |-> LogoutResponseCode, body |-> one] : one \in CheckedLogoutResponse }
        \cup { [tag |-> MassQuoteResponseCode, body |-> one] : one \in CheckedMassQuoteResponse }
        \cup { [tag |-> ModifyOrderNrResponseCode, body |-> one] : one \in CheckedModifyOrderNrResponse }
        \cup { [tag |-> ModifyOrderResponseCode, body |-> one] : one \in CheckedModifyOrderResponse }
        \cup { [tag |-> NewOrderNrResponseCode, body |-> one] : one \in CheckedNewOrderNrResponse }
        \cup { [tag |-> NewOrderResponseCode, body |-> one] : one \in CheckedNewOrderResponse }
        \cup { [tag |-> NewsBroadcastCode, body |-> one] : one \in CheckedNewsBroadcast }
        \cup { [tag |-> OrderExecNotificationCode, body |-> one] : one \in CheckedOrderExecNotification }
        \cup { [tag |-> OrderExecReportBroadcastCode, body |-> one] : one \in CheckedOrderExecReportBroadcast }
        \cup { [tag |-> OrderExecResponseCode, body |-> one] : one \in CheckedOrderExecResponse }
        \cup { [tag |-> PartyActionReportCode, body |-> one] : one \in CheckedPartyActionReport }
        \cup { [tag |-> PartyEntitlementsUpdateReportCode, body |-> one] : one \in CheckedPartyEntitlementsUpdateReport }
        \cup { [tag |-> QuoteActivationNotificationCode, body |-> one] : one \in CheckedQuoteActivationNotification }
        \cup { [tag |-> QuoteActivationResponseCode, body |-> one] : one \in CheckedQuoteActivationResponse }
        \cup { [tag |-> QuoteExecutionReportCode, body |-> one] : one \in CheckedQuoteExecutionReport }
        \cup { [tag |-> RfqBroadcastCode, body |-> one] : one \in CheckedRfqBroadcast }
        \cup { [tag |-> RfqRejectNotificationCode, body |-> one] : one \in CheckedRfqRejectNotification }
        \cup { [tag |-> RfqResponseCode, body |-> one] : one \in CheckedRfqResponse }
        \cup { [tag |-> RfqSpecialistBroadcastCode, body |-> one] : one \in CheckedRfqSpecialistBroadcast }
        \cup { [tag |-> RejectCode, body |-> one] : one \in CheckedReject }
        \cup { [tag |-> RetransmitMeMessageResponseCode, body |-> one] : one \in CheckedRetransmitMeMessageResponse }
        \cup { [tag |-> RetransmitResponseCode, body |-> one] : one \in CheckedRetransmitResponse }
        \cup { [tag |-> ServiceAvailabilityBroadcastCode, body |-> one] : one \in CheckedServiceAvailabilityBroadcast }
        \cup { [tag |-> ServiceAvailabilityMarketBroadcastCode, body |-> one] : one \in CheckedServiceAvailabilityMarketBroadcast }
        \cup { [tag |-> SpecialistDeleteAllOrderBroadcastCode, body |-> one] : one \in CheckedSpecialistDeleteAllOrderBroadcast }
        \cup { [tag |-> SpecialistInstrumentEventNotificationCode, body |-> one] : one \in CheckedSpecialistInstrumentEventNotification }
        \cup { [tag |-> SpecialistOrderBookNotificationCode, body |-> one] : one \in CheckedSpecialistOrderBookNotification }
        \cup { [tag |-> SpecialistRfqReplyNotificationCode, body |-> one] : one \in CheckedSpecialistRfqReplyNotification }
        \cup { [tag |-> SpecialistRfqReplyResponseCode, body |-> one] : one \in CheckedSpecialistRfqReplyResponse }
        \cup { [tag |-> SpecialistSecurityStateChangeResponseCode, body |-> one] : one \in CheckedSpecialistSecurityStateChangeResponse }
        \cup { [tag |-> SubscribeResponseCode, body |-> one] : one \in CheckedSubscribeResponse }
        \cup { [tag |-> TesApproveBroadcastCode, body |-> one] : one \in CheckedTesApproveBroadcast }
        \cup { [tag |-> TesBroadcastCode, body |-> one] : one \in CheckedTesBroadcast }
        \cup { [tag |-> TesDeleteBroadcastCode, body |-> one] : one \in CheckedTesDeleteBroadcast }
        \cup { [tag |-> TesExecutionBroadcastCode, body |-> one] : one \in CheckedTesExecutionBroadcast }
        \cup { [tag |-> TesResponseCode, body |-> one] : one \in CheckedTesResponse }
        \cup { [tag |-> TesTradeBroadcastCode, body |-> one] : one \in CheckedTesTradeBroadcast }
        \cup { [tag |-> TesTradingSessionStatusBroadcastCode, body |-> one] : one \in CheckedTesTradingSessionStatusBroadcast }
        \cup { [tag |-> TmTradingSessionStatusBroadcastCode, body |-> one] : one \in CheckedTmTradingSessionStatusBroadcast }
        \cup { [tag |-> ThrottleUpdateNotificationCode, body |-> one] : one \in CheckedThrottleUpdateNotification }
        \cup { [tag |-> TradeBroadcastCode, body |-> one] : one \in CheckedTradeBroadcast }
        \cup { [tag |-> TradingSessionStatusBroadcastCode, body |-> one] : one \in CheckedTradingSessionStatusBroadcast }
        \cup { [tag |-> TrailingStopUpdateNotificationCode, body |-> one] : one \in CheckedTrailingStopUpdateNotification }
        \cup { [tag |-> UnsubscribeResponseCode, body |-> one] : one \in CheckedUnsubscribeResponse }
        \cup { [tag |-> UserLoginResponseCode, body |-> one] : one \in CheckedUserLoginResponse }
        \cup { [tag |-> UserLogoutResponseCode, body |-> one] : one \in CheckedUserLogoutResponse }
        \cup { [tag |-> XetraEnLightCreateDealNotificationCode, body |-> one] : one \in CheckedXetraEnLightCreateDealNotification }
        \cup { [tag |-> XetraEnLightDealResponseCode, body |-> one] : one \in CheckedXetraEnLightDealResponse }
        \cup { [tag |-> XetraEnLightNegotiationNotificationCode, body |-> one] : one \in CheckedXetraEnLightNegotiationNotification }
        \cup { [tag |-> XetraEnLightNegotiationRequesterNotificationCode, body |-> one] : one \in CheckedXetraEnLightNegotiationRequesterNotification }
        \cup { [tag |-> XetraEnLightNegotiationStatusNotificationCode, body |-> one] : one \in CheckedXetraEnLightNegotiationStatusNotification }
        \cup { [tag |-> XetraEnLightOpenNegotiationNotificationCode, body |-> one] : one \in CheckedXetraEnLightOpenNegotiationNotification }
        \cup { [tag |-> XetraEnLightOpenNegotiationRequesterNotificationCode, body |-> one] : one \in CheckedXetraEnLightOpenNegotiationRequesterNotification }
        \cup { [tag |-> XetraEnLightQuoteNotificationCode, body |-> one] : one \in CheckedXetraEnLightQuoteNotification }
        \cup { [tag |-> XetraEnLightQuoteRequesterNotificationCode, body |-> one] : one \in CheckedXetraEnLightQuoteRequesterNotification }
        \cup { [tag |-> XetraEnLightQuoteResponseCode, body |-> one] : one \in CheckedXetraEnLightQuoteResponse }
        \cup { [tag |-> XetraEnLightStatusBroadcastCode, body |-> one] : one \in CheckedXetraEnLightStatusBroadcast }

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
    { [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> BestQuoteExecutionReportCode, body |-> ZeroBestQuoteExecutionReport]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> BestQuoteResponseCode, body |-> ZeroBestQuoteResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> BroadcastErrorNotificationCode, body |-> ZeroBroadcastErrorNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> CrossRequestResponseCode, body |-> ZeroCrossRequestResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllOrderBroadcastCode, body |-> ZeroDeleteAllOrderBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllOrderNrResponseCode, body |-> ZeroDeleteAllOrderNrResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllOrderQuoteEventBroadcastCode, body |-> ZeroDeleteAllOrderQuoteEventBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllOrderResponseCode, body |-> ZeroDeleteAllOrderResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllQuoteBroadcastCode, body |-> ZeroDeleteAllQuoteBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteAllQuoteResponseCode, body |-> ZeroDeleteAllQuoteResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteOrderBroadcastCode, body |-> ZeroDeleteOrderBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteOrderNrResponseCode, body |-> ZeroDeleteOrderNrResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> DeleteOrderResponseCode, body |-> ZeroDeleteOrderResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ExtendedDeletionReportCode, body |-> ZeroExtendedDeletionReport]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ForcedLogoutNotificationCode, body |-> ZeroForcedLogoutNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ForcedUserLogoutNotificationCode, body |-> ZeroForcedUserLogoutNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> HeartbeatNotificationCode, body |-> ZeroHeartbeatNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> InquireEnrichmentRuleIdListResponseCode, body |-> ZeroInquireEnrichmentRuleIdListResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> InquireSessionListResponseCode, body |-> ZeroInquireSessionListResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> InquireUserResponseCode, body |-> ZeroInquireUserResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> IssuerNotificationCode, body |-> ZeroIssuerNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> IssuerSecurityStateChangeResponseCode, body |-> ZeroIssuerSecurityStateChangeResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> LegalNotificationBroadcastCode, body |-> ZeroLegalNotificationBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> LogonResponseCode, body |-> ZeroLogonResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> LogoutResponseCode, body |-> ZeroLogoutResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> MassQuoteResponseCode, body |-> ZeroMassQuoteResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ModifyOrderNrResponseCode, body |-> ZeroModifyOrderNrResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ModifyOrderResponseCode, body |-> ZeroModifyOrderResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> NewOrderNrResponseCode, body |-> ZeroNewOrderNrResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> NewOrderResponseCode, body |-> ZeroNewOrderResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> NewsBroadcastCode, body |-> ZeroNewsBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderExecNotificationCode, body |-> ZeroOrderExecNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderExecReportBroadcastCode, body |-> ZeroOrderExecReportBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> OrderExecResponseCode, body |-> ZeroOrderExecResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> PartyActionReportCode, body |-> ZeroPartyActionReport]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> PartyEntitlementsUpdateReportCode, body |-> ZeroPartyEntitlementsUpdateReport]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> QuoteActivationNotificationCode, body |-> ZeroQuoteActivationNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> QuoteActivationResponseCode, body |-> ZeroQuoteActivationResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> QuoteExecutionReportCode, body |-> ZeroQuoteExecutionReport]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RfqBroadcastCode, body |-> ZeroRfqBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RfqRejectNotificationCode, body |-> ZeroRfqRejectNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RfqResponseCode, body |-> ZeroRfqResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RfqSpecialistBroadcastCode, body |-> ZeroRfqSpecialistBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RejectCode, body |-> ZeroReject]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RetransmitMeMessageResponseCode, body |-> ZeroRetransmitMeMessageResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RetransmitResponseCode, body |-> ZeroRetransmitResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ServiceAvailabilityBroadcastCode, body |-> ZeroServiceAvailabilityBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ServiceAvailabilityMarketBroadcastCode, body |-> ZeroServiceAvailabilityMarketBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SpecialistDeleteAllOrderBroadcastCode, body |-> ZeroSpecialistDeleteAllOrderBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SpecialistInstrumentEventNotificationCode, body |-> ZeroSpecialistInstrumentEventNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SpecialistOrderBookNotificationCode, body |-> ZeroSpecialistOrderBookNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SpecialistRfqReplyNotificationCode, body |-> ZeroSpecialistRfqReplyNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SpecialistRfqReplyResponseCode, body |-> ZeroSpecialistRfqReplyResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SpecialistSecurityStateChangeResponseCode, body |-> ZeroSpecialistSecurityStateChangeResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SubscribeResponseCode, body |-> ZeroSubscribeResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TesApproveBroadcastCode, body |-> ZeroTesApproveBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TesBroadcastCode, body |-> ZeroTesBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TesDeleteBroadcastCode, body |-> ZeroTesDeleteBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TesExecutionBroadcastCode, body |-> ZeroTesExecutionBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TesResponseCode, body |-> ZeroTesResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TesTradeBroadcastCode, body |-> ZeroTesTradeBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TesTradingSessionStatusBroadcastCode, body |-> ZeroTesTradingSessionStatusBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TmTradingSessionStatusBroadcastCode, body |-> ZeroTmTradingSessionStatusBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ThrottleUpdateNotificationCode, body |-> ZeroThrottleUpdateNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TradeBroadcastCode, body |-> ZeroTradeBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TradingSessionStatusBroadcastCode, body |-> ZeroTradingSessionStatusBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TrailingStopUpdateNotificationCode, body |-> ZeroTrailingStopUpdateNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UnsubscribeResponseCode, body |-> ZeroUnsubscribeResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UserLoginResponseCode, body |-> ZeroUserLoginResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UserLogoutResponseCode, body |-> ZeroUserLogoutResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightCreateDealNotificationCode, body |-> ZeroXetraEnLightCreateDealNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightDealResponseCode, body |-> ZeroXetraEnLightDealResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightNegotiationNotificationCode, body |-> ZeroXetraEnLightNegotiationNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightNegotiationRequesterNotificationCode, body |-> ZeroXetraEnLightNegotiationRequesterNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightNegotiationStatusNotificationCode, body |-> ZeroXetraEnLightNegotiationStatusNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightOpenNegotiationNotificationCode, body |-> ZeroXetraEnLightOpenNegotiationNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightOpenNegotiationRequesterNotificationCode, body |-> ZeroXetraEnLightOpenNegotiationRequesterNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightQuoteNotificationCode, body |-> ZeroXetraEnLightQuoteNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightQuoteRequesterNotificationCode, body |-> ZeroXetraEnLightQuoteRequesterNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightQuoteResponseCode, body |-> ZeroXetraEnLightQuoteResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> XetraEnLightStatusBroadcastCode, body |-> ZeroXetraEnLightStatusBroadcast]] }

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

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp ==
    \A message \in CheckedRbcHeaderMeComp :
        LET read == DecodeRbcHeaderMeComp(EncodeRbcHeaderMeComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Quote Execution Report decodes back to what was encoded, and leaves nothing over *)
RoundTripBestQuoteExecutionReport ==
    \A message \in CheckedBestQuoteExecutionReport :
        LET read == DecodeBestQuoteExecutionReport(EncodeBestQuoteExecutionReport(message))
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

(* Every Best Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripBestQuoteResponse ==
    \A message \in CheckedBestQuoteResponse :
        LET read == DecodeBestQuoteResponse(EncodeBestQuoteResponse(message))
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

(* Every Broadcast Error Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripBroadcastErrorNotification ==
    \A message \in CheckedBroadcastErrorNotification :
        LET read == DecodeBroadcastErrorNotification(EncodeBroadcastErrorNotification(message))
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

(* Every Cross Request Response decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossRequestResponse ==
    \A message \in CheckedCrossRequestResponse :
        LET read == DecodeCrossRequestResponse(EncodeCrossRequestResponse(message))
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

(* Every Not Affected Orders Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotAffectedOrdersGrpComp ==
    \A message \in CheckedNotAffectedOrdersGrpComp :
        LET read == DecodeNotAffectedOrdersGrpComp(EncodeNotAffectedOrdersGrpComp(message))
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

(* Every Affected Order Requests Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripAffectedOrderRequestsGrpComp ==
    \A message \in CheckedAffectedOrderRequestsGrpComp :
        LET read == DecodeAffectedOrderRequestsGrpComp(EncodeAffectedOrderRequestsGrpComp(message))
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
RoundTripNrResponseHeaderMeComp3 ==
    \A message \in CheckedNrResponseHeaderMeComp3 :
        LET read == DecodeNrResponseHeaderMeComp3(EncodeNrResponseHeaderMeComp3(message))
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
RoundTripRbcHeaderMeComp3 ==
    \A message \in CheckedRbcHeaderMeComp3 :
        LET read == DecodeRbcHeaderMeComp3(EncodeRbcHeaderMeComp3(message))
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

(* Every Affected Ord Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripAffectedOrdGrpComp2 ==
    \A message \in CheckedAffectedOrdGrpComp2 :
        LET read == DecodeAffectedOrdGrpComp2(EncodeAffectedOrdGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Affected Order Requests Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripAffectedOrderRequestsGrpComp2 ==
    \A message \in CheckedAffectedOrderRequestsGrpComp2 :
        LET read == DecodeAffectedOrderRequestsGrpComp2(EncodeAffectedOrderRequestsGrpComp2(message))
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
RoundTripRbcHeaderMeComp4 ==
    \A message \in CheckedRbcHeaderMeComp4 :
        LET read == DecodeRbcHeaderMeComp4(EncodeRbcHeaderMeComp4(message))
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
RoundTripNrResponseHeaderMeComp4 ==
    \A message \in CheckedNrResponseHeaderMeComp4 :
        LET read == DecodeNrResponseHeaderMeComp4(EncodeNrResponseHeaderMeComp4(message))
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
RoundTripRbcHeaderMeComp5 ==
    \A message \in CheckedRbcHeaderMeComp5 :
        LET read == DecodeRbcHeaderMeComp5(EncodeRbcHeaderMeComp5(message))
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
RoundTripNrResponseHeaderMeComp5 ==
    \A message \in CheckedNrResponseHeaderMeComp5 :
        LET read == DecodeNrResponseHeaderMeComp5(EncodeNrResponseHeaderMeComp5(message))
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

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp6 ==
    \A message \in CheckedRbcHeaderMeComp6 :
        LET read == DecodeRbcHeaderMeComp6(EncodeRbcHeaderMeComp6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Extended Deletion Report decodes back to what was encoded, and leaves nothing over *)
RoundTripExtendedDeletionReport ==
    \A message \in CheckedExtendedDeletionReport :
        LET read == DecodeExtendedDeletionReport(EncodeExtendedDeletionReport(message))
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

(* Every Notif Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotifHeaderComp3 ==
    \A message \in CheckedNotifHeaderComp3 :
        LET read == DecodeNotifHeaderComp3(EncodeNotifHeaderComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Forced User Logout Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripForcedUserLogoutNotification ==
    \A message \in CheckedForcedUserLogoutNotification :
        LET read == DecodeForcedUserLogoutNotification(EncodeForcedUserLogoutNotification(message))
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

(* Every Enrichment Rules Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripEnrichmentRulesGrpComp ==
    \A message \in CheckedEnrichmentRulesGrpComp :
        LET read == DecodeEnrichmentRulesGrpComp(EncodeEnrichmentRulesGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire Enrichment Rule Id List Response decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireEnrichmentRuleIdListResponse ==
    \A message \in CheckedInquireEnrichmentRuleIdListResponse :
        LET read == DecodeInquireEnrichmentRuleIdListResponse(EncodeInquireEnrichmentRuleIdListResponse(message))
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
RoundTripResponseHeaderComp3 ==
    \A message \in CheckedResponseHeaderComp3 :
        LET read == DecodeResponseHeaderComp3(EncodeResponseHeaderComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsGrpComp ==
    \A message \in CheckedPartyDetailsGrpComp :
        LET read == DecodePartyDetailsGrpComp(EncodePartyDetailsGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire User Response decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireUserResponse ==
    \A message \in CheckedInquireUserResponse :
        LET read == DecodeInquireUserResponse(EncodeInquireUserResponse(message))
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

(* Every Issuer Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripIssuerNotification ==
    \A message \in CheckedIssuerNotification :
        LET read == DecodeIssuerNotification(EncodeIssuerNotification(message))
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

(* Every Issuer Security State Change Response decodes back to what was encoded, and leaves nothing over *)
RoundTripIssuerSecurityStateChangeResponse ==
    \A message \in CheckedIssuerSecurityStateChangeResponse :
        LET read == DecodeIssuerSecurityStateChangeResponse(EncodeIssuerSecurityStateChangeResponse(message))
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

(* Every Legal Notification Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripLegalNotificationBroadcast ==
    \A message \in CheckedLegalNotificationBroadcast :
        LET read == DecodeLegalNotificationBroadcast(EncodeLegalNotificationBroadcast(message))
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
RoundTripNrResponseHeaderMeComp7 ==
    \A message \in CheckedNrResponseHeaderMeComp7 :
        LET read == DecodeNrResponseHeaderMeComp7(EncodeNrResponseHeaderMeComp7(message))
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
RoundTripNrResponseHeaderMeComp8 ==
    \A message \in CheckedNrResponseHeaderMeComp8 :
        LET read == DecodeNrResponseHeaderMeComp8(EncodeNrResponseHeaderMeComp8(message))
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

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp9 ==
    \A message \in CheckedNrResponseHeaderMeComp9 :
        LET read == DecodeNrResponseHeaderMeComp9(EncodeNrResponseHeaderMeComp9(message))
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
RoundTripResponseHeaderMeComp4 ==
    \A message \in CheckedResponseHeaderMeComp4 :
        LET read == DecodeResponseHeaderMeComp4(EncodeResponseHeaderMeComp4(message))
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
RoundTripRbcHeaderComp2 ==
    \A message \in CheckedRbcHeaderComp2 :
        LET read == DecodeRbcHeaderComp2(EncodeRbcHeaderComp2(message))
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
RoundTripRbcHeaderMeComp8 ==
    \A message \in CheckedRbcHeaderMeComp8 :
        LET read == DecodeRbcHeaderMeComp8(EncodeRbcHeaderMeComp8(message))
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

(* Every Order Exec Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecNotification ==
    \A message \in CheckedOrderExecNotification :
        LET read == DecodeOrderExecNotification(EncodeOrderExecNotification(message))
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

(* Every Fills Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGrpComp2 ==
    \A message \in CheckedFillsGrpComp2 :
        LET read == DecodeFillsGrpComp2(EncodeFillsGrpComp2(message))
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
RoundTripResponseHeaderMeComp5 ==
    \A message \in CheckedResponseHeaderMeComp5 :
        LET read == DecodeResponseHeaderMeComp5(EncodeResponseHeaderMeComp5(message))
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

(* Every Order Exec Response decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecResponse ==
    \A message \in CheckedOrderExecResponse :
        LET read == DecodeOrderExecResponse(EncodeOrderExecResponse(message))
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

(* Every Party Action Report decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyActionReport ==
    \A message \in CheckedPartyActionReport :
        LET read == DecodePartyActionReport(EncodePartyActionReport(message))
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

(* Every Party Entitlements Update Report decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyEntitlementsUpdateReport ==
    \A message \in CheckedPartyEntitlementsUpdateReport :
        LET read == DecodePartyEntitlementsUpdateReport(EncodePartyEntitlementsUpdateReport(message))
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

(* Every Not Affected Securities Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotAffectedSecuritiesGrpComp3 ==
    \A message \in CheckedNotAffectedSecuritiesGrpComp3 :
        LET read == DecodeNotAffectedSecuritiesGrpComp3(EncodeNotAffectedSecuritiesGrpComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Activation Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteActivationNotification ==
    \A message \in CheckedQuoteActivationNotification :
        LET read == DecodeQuoteActivationNotification(EncodeQuoteActivationNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp10 ==
    \A message \in CheckedNrResponseHeaderMeComp10 :
        LET read == DecodeNrResponseHeaderMeComp10(EncodeNrResponseHeaderMeComp10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Affected Securities Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotAffectedSecuritiesGrpComp4 ==
    \A message \in CheckedNotAffectedSecuritiesGrpComp4 :
        LET read == DecodeNotAffectedSecuritiesGrpComp4(EncodeNotAffectedSecuritiesGrpComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Activation Response decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteActivationResponse ==
    \A message \in CheckedQuoteActivationResponse :
        LET read == DecodeQuoteActivationResponse(EncodeQuoteActivationResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp11 ==
    \A message \in CheckedRbcHeaderMeComp11 :
        LET read == DecodeRbcHeaderMeComp11(EncodeRbcHeaderMeComp11(message))
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

(* Every Quote Execution Report decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteExecutionReport ==
    \A message \in CheckedQuoteExecutionReport :
        LET read == DecodeQuoteExecutionReport(EncodeQuoteExecutionReport(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp12 ==
    \A message \in CheckedRbcHeaderMeComp12 :
        LET read == DecodeRbcHeaderMeComp12(EncodeRbcHeaderMeComp12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqBroadcast ==
    \A message \in CheckedRfqBroadcast :
        LET read == DecodeRfqBroadcast(EncodeRfqBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp13 ==
    \A message \in CheckedRbcHeaderMeComp13 :
        LET read == DecodeRbcHeaderMeComp13(EncodeRbcHeaderMeComp13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Reject Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqRejectNotification ==
    \A message \in CheckedRfqRejectNotification :
        LET read == DecodeRfqRejectNotification(EncodeRfqRejectNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp11 ==
    \A message \in CheckedNrResponseHeaderMeComp11 :
        LET read == DecodeNrResponseHeaderMeComp11(EncodeNrResponseHeaderMeComp11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Response decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqResponse ==
    \A message \in CheckedRfqResponse :
        LET read == DecodeRfqResponse(EncodeRfqResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp14 ==
    \A message \in CheckedRbcHeaderMeComp14 :
        LET read == DecodeRbcHeaderMeComp14(EncodeRbcHeaderMeComp14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Specialist Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqSpecialistBroadcast ==
    \A message \in CheckedRfqSpecialistBroadcast :
        LET read == DecodeRfqSpecialistBroadcast(EncodeRfqSpecialistBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp12 ==
    \A message \in CheckedNrResponseHeaderMeComp12 :
        LET read == DecodeNrResponseHeaderMeComp12(EncodeNrResponseHeaderMeComp12(message))
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

(* Every Nrbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrbcHeaderComp2 ==
    \A message \in CheckedNrbcHeaderComp2 :
        LET read == DecodeNrbcHeaderComp2(EncodeNrbcHeaderComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Service Availability Market Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripServiceAvailabilityMarketBroadcast ==
    \A message \in CheckedServiceAvailabilityMarketBroadcast :
        LET read == DecodeServiceAvailabilityMarketBroadcast(EncodeServiceAvailabilityMarketBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp15 ==
    \A message \in CheckedRbcHeaderMeComp15 :
        LET read == DecodeRbcHeaderMeComp15(EncodeRbcHeaderMeComp15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Affected Ord Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripAffectedOrdGrpComp3 ==
    \A message \in CheckedAffectedOrdGrpComp3 :
        LET read == DecodeAffectedOrdGrpComp3(EncodeAffectedOrdGrpComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Affected Orders Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNotAffectedOrdersGrpComp3 ==
    \A message \in CheckedNotAffectedOrdersGrpComp3 :
        LET read == DecodeNotAffectedOrdersGrpComp3(EncodeNotAffectedOrdersGrpComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Specialist Delete All Order Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialistDeleteAllOrderBroadcast ==
    \A message \in CheckedSpecialistDeleteAllOrderBroadcast :
        LET read == DecodeSpecialistDeleteAllOrderBroadcast(EncodeSpecialistDeleteAllOrderBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp16 ==
    \A message \in CheckedRbcHeaderMeComp16 :
        LET read == DecodeRbcHeaderMeComp16(EncodeRbcHeaderMeComp16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Specialist Instrument Event Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialistInstrumentEventNotification ==
    \A message \in CheckedSpecialistInstrumentEventNotification :
        LET read == DecodeSpecialistInstrumentEventNotification(EncodeSpecialistInstrumentEventNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp17 ==
    \A message \in CheckedRbcHeaderMeComp17 :
        LET read == DecodeRbcHeaderMeComp17(EncodeRbcHeaderMeComp17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fills Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripFillsGrpComp4 ==
    \A message \in CheckedFillsGrpComp4 :
        LET read == DecodeFillsGrpComp4(EncodeFillsGrpComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Specialist Order Book Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialistOrderBookNotification ==
    \A message \in CheckedSpecialistOrderBookNotification :
        LET read == DecodeSpecialistOrderBookNotification(EncodeSpecialistOrderBookNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp18 ==
    \A message \in CheckedRbcHeaderMeComp18 :
        LET read == DecodeRbcHeaderMeComp18(EncodeRbcHeaderMeComp18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Specialist Rfq Reply Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialistRfqReplyNotification ==
    \A message \in CheckedSpecialistRfqReplyNotification :
        LET read == DecodeSpecialistRfqReplyNotification(EncodeSpecialistRfqReplyNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp13 ==
    \A message \in CheckedNrResponseHeaderMeComp13 :
        LET read == DecodeNrResponseHeaderMeComp13(EncodeNrResponseHeaderMeComp13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Specialist Rfq Reply Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialistRfqReplyResponse ==
    \A message \in CheckedSpecialistRfqReplyResponse :
        LET read == DecodeSpecialistRfqReplyResponse(EncodeSpecialistRfqReplyResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp14 ==
    \A message \in CheckedNrResponseHeaderMeComp14 :
        LET read == DecodeNrResponseHeaderMeComp14(EncodeNrResponseHeaderMeComp14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Specialist Security State Change Response decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialistSecurityStateChangeResponse ==
    \A message \in CheckedSpecialistSecurityStateChangeResponse :
        LET read == DecodeSpecialistSecurityStateChangeResponse(EncodeSpecialistSecurityStateChangeResponse(message))
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

(* Every Tes Approve Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTesApproveBroadcast ==
    \A message \in CheckedTesApproveBroadcast :
        LET read == DecodeTesApproveBroadcast(EncodeTesApproveBroadcast(message))
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

(* Every Side Alloc Grp Bc Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSideAllocGrpBcComp ==
    \A message \in CheckedSideAllocGrpBcComp :
        LET read == DecodeSideAllocGrpBcComp(EncodeSideAllocGrpBcComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tes Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTesBroadcast ==
    \A message \in CheckedTesBroadcast :
        LET read == DecodeTesBroadcast(EncodeTesBroadcast(message))
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

(* Every Tes Delete Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTesDeleteBroadcast ==
    \A message \in CheckedTesDeleteBroadcast :
        LET read == DecodeTesDeleteBroadcast(EncodeTesDeleteBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp8 ==
    \A message \in CheckedRbcHeaderComp8 :
        LET read == DecodeRbcHeaderComp8(EncodeRbcHeaderComp8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tes Execution Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTesExecutionBroadcast ==
    \A message \in CheckedTesExecutionBroadcast :
        LET read == DecodeTesExecutionBroadcast(EncodeTesExecutionBroadcast(message))
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

(* Every Tes Response decodes back to what was encoded, and leaves nothing over *)
RoundTripTesResponse ==
    \A message \in CheckedTesResponse :
        LET read == DecodeTesResponse(EncodeTesResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp9 ==
    \A message \in CheckedRbcHeaderComp9 :
        LET read == DecodeRbcHeaderComp9(EncodeRbcHeaderComp9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tes Trade Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTesTradeBroadcast ==
    \A message \in CheckedTesTradeBroadcast :
        LET read == DecodeTesTradeBroadcast(EncodeTesTradeBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp10 ==
    \A message \in CheckedRbcHeaderComp10 :
        LET read == DecodeRbcHeaderComp10(EncodeRbcHeaderComp10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tes Trading Session Status Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripTesTradingSessionStatusBroadcast ==
    \A message \in CheckedTesTradingSessionStatusBroadcast :
        LET read == DecodeTesTradingSessionStatusBroadcast(EncodeTesTradingSessionStatusBroadcast(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp11 ==
    \A message \in CheckedRbcHeaderComp11 :
        LET read == DecodeRbcHeaderComp11(EncodeRbcHeaderComp11(message))
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
RoundTripNotifHeaderComp5 ==
    \A message \in CheckedNotifHeaderComp5 :
        LET read == DecodeNotifHeaderComp5(EncodeNotifHeaderComp5(message))
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
RoundTripRbcHeaderComp12 ==
    \A message \in CheckedRbcHeaderComp12 :
        LET read == DecodeRbcHeaderComp12(EncodeRbcHeaderComp12(message))
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

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp19 ==
    \A message \in CheckedRbcHeaderMeComp19 :
        LET read == DecodeRbcHeaderMeComp19(EncodeRbcHeaderMeComp19(message))
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

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp20 ==
    \A message \in CheckedRbcHeaderMeComp20 :
        LET read == DecodeRbcHeaderMeComp20(EncodeRbcHeaderMeComp20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trailing Stop Update Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripTrailingStopUpdateNotification ==
    \A message \in CheckedTrailingStopUpdateNotification :
        LET read == DecodeTrailingStopUpdateNotification(EncodeTrailingStopUpdateNotification(message))
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

(* Every Unsubscribe Response decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsubscribeResponse ==
    \A message \in CheckedUnsubscribeResponse :
        LET read == DecodeUnsubscribeResponse(EncodeUnsubscribeResponse(message))
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

(* Every User Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLoginResponse ==
    \A message \in CheckedUserLoginResponse :
        LET read == DecodeUserLoginResponse(EncodeUserLoginResponse(message))
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

(* Every User Logout Response decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLogoutResponse ==
    \A message \in CheckedUserLogoutResponse :
        LET read == DecodeUserLogoutResponse(EncodeUserLogoutResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp13 ==
    \A message \in CheckedRbcHeaderComp13 :
        LET read == DecodeRbcHeaderComp13(EncodeRbcHeaderComp13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Item Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookItemGrpComp ==
    \A message \in CheckedOrderBookItemGrpComp :
        LET read == DecodeOrderBookItemGrpComp(EncodeOrderBookItemGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Create Deal Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightCreateDealNotification ==
    \A message \in CheckedXetraEnLightCreateDealNotification :
        LET read == DecodeXetraEnLightCreateDealNotification(EncodeXetraEnLightCreateDealNotification(message))
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

(* Every Xetra En Light Deal Response decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightDealResponse ==
    \A message \in CheckedXetraEnLightDealResponse :
        LET read == DecodeXetraEnLightDealResponse(EncodeXetraEnLightDealResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp14 ==
    \A message \in CheckedRbcHeaderComp14 :
        LET read == DecodeRbcHeaderComp14(EncodeRbcHeaderComp14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Negotiation Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightNegotiationNotification ==
    \A message \in CheckedXetraEnLightNegotiationNotification :
        LET read == DecodeXetraEnLightNegotiationNotification(EncodeXetraEnLightNegotiationNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp15 ==
    \A message \in CheckedRbcHeaderComp15 :
        LET read == DecodeRbcHeaderComp15(EncodeRbcHeaderComp15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Target Parties Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightTargetPartiesComp ==
    \A message \in CheckedXetraEnLightTargetPartiesComp :
        LET read == DecodeXetraEnLightTargetPartiesComp(EncodeXetraEnLightTargetPartiesComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Negotiation Requester Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightNegotiationRequesterNotification ==
    \A message \in CheckedXetraEnLightNegotiationRequesterNotification :
        LET read == DecodeXetraEnLightNegotiationRequesterNotification(EncodeXetraEnLightNegotiationRequesterNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp16 ==
    \A message \in CheckedRbcHeaderComp16 :
        LET read == DecodeRbcHeaderComp16(EncodeRbcHeaderComp16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Negotiation Status Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightNegotiationStatusNotification ==
    \A message \in CheckedXetraEnLightNegotiationStatusNotification :
        LET read == DecodeXetraEnLightNegotiationStatusNotification(EncodeXetraEnLightNegotiationStatusNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp17 ==
    \A message \in CheckedRbcHeaderComp17 :
        LET read == DecodeRbcHeaderComp17(EncodeRbcHeaderComp17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Open Negotiation Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightOpenNegotiationNotification ==
    \A message \in CheckedXetraEnLightOpenNegotiationNotification :
        LET read == DecodeXetraEnLightOpenNegotiationNotification(EncodeXetraEnLightOpenNegotiationNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp18 ==
    \A message \in CheckedRbcHeaderComp18 :
        LET read == DecodeRbcHeaderComp18(EncodeRbcHeaderComp18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Target Parties Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightTargetPartiesComp2 ==
    \A message \in CheckedXetraEnLightTargetPartiesComp2 :
        LET read == DecodeXetraEnLightTargetPartiesComp2(EncodeXetraEnLightTargetPartiesComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Open Negotiation Requester Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightOpenNegotiationRequesterNotification ==
    \A message \in CheckedXetraEnLightOpenNegotiationRequesterNotification :
        LET read == DecodeXetraEnLightOpenNegotiationRequesterNotification(EncodeXetraEnLightOpenNegotiationRequesterNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp19 ==
    \A message \in CheckedRbcHeaderComp19 :
        LET read == DecodeRbcHeaderComp19(EncodeRbcHeaderComp19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Quote Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightQuoteNotification ==
    \A message \in CheckedXetraEnLightQuoteNotification :
        LET read == DecodeXetraEnLightQuoteNotification(EncodeXetraEnLightQuoteNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp20 ==
    \A message \in CheckedRbcHeaderComp20 :
        LET read == DecodeRbcHeaderComp20(EncodeRbcHeaderComp20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Srqs Quote Entry Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSrqsQuoteEntryGrpComp ==
    \A message \in CheckedSrqsQuoteEntryGrpComp :
        LET read == DecodeSrqsQuoteEntryGrpComp(EncodeSrqsQuoteEntryGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Quote Requester Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightQuoteRequesterNotification ==
    \A message \in CheckedXetraEnLightQuoteRequesterNotification :
        LET read == DecodeXetraEnLightQuoteRequesterNotification(EncodeXetraEnLightQuoteRequesterNotification(message))
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

(* Every Xetra En Light Quote Response decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightQuoteResponse ==
    \A message \in CheckedXetraEnLightQuoteResponse :
        LET read == DecodeXetraEnLightQuoteResponse(EncodeXetraEnLightQuoteResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rbc Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderComp21 ==
    \A message \in CheckedRbcHeaderComp21 :
        LET read == DecodeRbcHeaderComp21(EncodeRbcHeaderComp21(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Status Broadcast decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightStatusBroadcast ==
    \A message \in CheckedXetraEnLightStatusBroadcast :
        LET read == DecodeXetraEnLightStatusBroadcast(EncodeXetraEnLightStatusBroadcast(message))
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
