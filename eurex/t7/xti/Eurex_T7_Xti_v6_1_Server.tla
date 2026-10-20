--------------------- MODULE Eurex_T7_Xti_v6_1_Server ----------------------
(***************************************************************************)
(* Eurex Exchange Cash Enhanced Trading Interface v6.1                     *)
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
(* Note: Gateway Response fills what is left of the frame Body Len states, *)
(* which is what it is read from.                                          *)
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
(* Note: Rfq Response fills what is left of the frame Body Len states,     *)
(* which is what it is read from.                                          *)
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
(* Best Quote Execution Report: 114 bytes                                  *)
(***************************************************************************)

BestQuoteExecutionReport ==
    [ pad2              : Sample(2),
      rbcHeaderMeComp   : RbcHeaderMeComp,
      execId            : Sample(8),
      quoteMsgId        : Sample(8),
      securityId        : Sample(8),
      quoteEventPx      : Sample(8),
      marketSegmentId   : Sample(4),
      quoteEventMatchId : Sample(4),
      quoteEventExecId  : Sample(4),
      quoteEventQty     : Sample(4),
      reservedSize      : Sample(4),
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
        \o message.marketSegmentId
        \o message.quoteEventMatchId
        \o message.quoteEventExecId
        \o message.quoteEventQty
        \o message.reservedSize
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
    LET marketSegmentId == ReadBytes(quoteEventPx.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET quoteEventMatchId == ReadBytes(marketSegmentId.rest, 4) IN IF ~quoteEventMatchId.ok THEN Fail ELSE
    LET quoteEventExecId == ReadBytes(quoteEventMatchId.rest, 4) IN IF ~quoteEventExecId.ok THEN Fail ELSE
    LET quoteEventQty == ReadBytes(quoteEventExecId.rest, 4) IN IF ~quoteEventQty.ok THEN Fail ELSE
    LET reservedSize == ReadBytes(quoteEventQty.rest, 4) IN IF ~reservedSize.ok THEN Fail ELSE
    LET quoteEventType == ReadBytes(reservedSize.rest, 1) IN IF ~quoteEventType.ok THEN Fail ELSE
    LET quoteEventSide == ReadBytes(quoteEventType.rest, 1) IN IF ~quoteEventSide.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(quoteEventSide.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ pad2              |-> pad2.value,
         rbcHeaderMeComp   |-> rbcHeaderMeComp.value,
         execId            |-> execId.value,
         quoteMsgId        |-> quoteMsgId.value,
         securityId        |-> securityId.value,
         quoteEventPx      |-> quoteEventPx.value,
         marketSegmentId   |-> marketSegmentId.value,
         quoteEventMatchId |-> quoteEventMatchId.value,
         quoteEventExecId  |-> quoteEventExecId.value,
         quoteEventQty     |-> quoteEventQty.value,
         reservedSize      |-> reservedSize.value,
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
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      quoteEventMatchId |-> [i \in 1 .. 4 |-> 0],
      quoteEventExecId  |-> [i \in 1 .. 4 |-> 0],
      quoteEventQty     |-> [i \in 1 .. 4 |-> 0],
      reservedSize      |-> [i \in 1 .. 4 |-> 0],
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
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventMatchId = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventQty = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.reservedSize = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventType = one] : one \in Sample(1) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.quoteEventSide = one] : one \in Sample(1) }
        \cup { [ZeroBestQuoteExecutionReport EXCEPT !.pad2v2 = one] : one \in Sample(2) }

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
(* Best Quote Response: 98 bytes                                           *)
(***************************************************************************)

BestQuoteResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp,
      quoteId                : Sample(8),
      quoteResponseId        : Sample(8),
      securityId             : Sample(8),
      marketSegmentId        : Sample(4),
      bidCxlSize             : Sample(4),
      offerCxlSize           : Sample(4),
      pad4                   : Sample(4) ]

EncodeBestQuoteResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp(message.nrResponseHeaderMeComp)
        \o message.quoteId
        \o message.quoteResponseId
        \o message.securityId
        \o message.marketSegmentId
        \o message.bidCxlSize
        \o message.offerCxlSize
        \o message.pad4

DecodeBestQuoteResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteResponseId == ReadBytes(quoteId.rest, 8) IN IF ~quoteResponseId.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteResponseId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(securityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET bidCxlSize == ReadBytes(marketSegmentId.rest, 4) IN IF ~bidCxlSize.ok THEN Fail ELSE
    LET offerCxlSize == ReadBytes(bidCxlSize.rest, 4) IN IF ~offerCxlSize.ok THEN Fail ELSE
    LET pad4 == ReadBytes(offerCxlSize.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         quoteId                |-> quoteId.value,
         quoteResponseId        |-> quoteResponseId.value,
         securityId             |-> securityId.value,
         marketSegmentId        |-> marketSegmentId.value,
         bidCxlSize             |-> bidCxlSize.value,
         offerCxlSize           |-> offerCxlSize.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroBestQuoteResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp,
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      quoteResponseId        |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      bidCxlSize             |-> [i \in 1 .. 4 |-> 0],
      offerCxlSize           |-> [i \in 1 .. 4 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Best Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedBestQuoteResponse ==
    { ZeroBestQuoteResponse }
        \cup { [ZeroBestQuoteResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp }
        \cup { [ZeroBestQuoteResponse EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.quoteResponseId = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.bidCxlSize = one] : one \in Sample(4) }
        \cup { [ZeroBestQuoteResponse EXCEPT !.offerCxlSize = one] : one \in Sample(4) }
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
(* Cross Request Response: 66 bytes                                        *)
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
      notAffectedOrdersGrpComp     : SampleLists(OneNotAffectedOrdersGrpComp),
      affectedOrdGrpComp           : SampleLists(OneAffectedOrdGrpComp) ]

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
        \o message.partyIdEnteringFirm
        \o message.massActionReason
        \o message.execInst
        \o message.side
        \o EncodeNotAffectedOrdersGrpCompList(message.notAffectedOrdersGrpComp)
        \o EncodeAffectedOrdGrpCompList(message.affectedOrdGrpComp)

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
    LET partyIdEnteringFirm == ReadBytes(noAffectedOrders.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET massActionReason == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~massActionReason.ok THEN Fail ELSE
    LET execInst == ReadBytes(massActionReason.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET side == ReadBytes(execInst.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET notAffectedOrdersGrpComp == ReadNotAffectedOrdersGrpCompList(side.rest, noNotAffectedOrders.value) IN IF ~notAffectedOrdersGrpComp.ok THEN Fail ELSE
    LET affectedOrdGrpComp == ReadAffectedOrdGrpCompList(notAffectedOrdersGrpComp.rest, noAffectedOrders.value) IN IF ~affectedOrdGrpComp.ok THEN Fail ELSE
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
         notAffectedOrdersGrpComp     |-> notAffectedOrdersGrpComp.value,
         affectedOrdGrpComp           |-> affectedOrdGrpComp.value ], affectedOrdGrpComp.rest)

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
      notAffectedOrdersGrpComp     |-> << >>,
      affectedOrdGrpComp           |-> << >> ]

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
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.notAffectedOrdersGrpComp = one] : one \in SampleLists(OneNotAffectedOrdersGrpComp) }
        \cup { [ZeroDeleteAllOrderBroadcast EXCEPT !.affectedOrdGrpComp = one] : one \in SampleLists(OneAffectedOrdGrpComp) }

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
(* Delete All Order Nr Response: 66 bytes                                  *)
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
(* Delete All Order Response                                               *)
(***************************************************************************)

DeleteAllOrderResponse ==
    [ pad2                     : Sample(2),
      responseHeaderMeComp     : ResponseHeaderMeComp,
      massActionReportId       : Sample(8),
      pad4                     : Sample(4),
      notAffectedOrdersGrpComp : SampleLists(OneNotAffectedOrdersGrpComp2),
      affectedOrdGrpComp       : SampleLists(OneAffectedOrdGrpComp2) ]

EncodeDeleteAllOrderResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderMeComp(message.responseHeaderMeComp)
        \o message.massActionReportId
        \o EncodeUIntLE(Len(message.notAffectedOrdersGrpComp), 2)
        \o EncodeUIntLE(Len(message.affectedOrdGrpComp), 2)
        \o message.pad4
        \o EncodeNotAffectedOrdersGrpComp2List(message.notAffectedOrdersGrpComp)
        \o EncodeAffectedOrdGrpComp2List(message.affectedOrdGrpComp)

DecodeDeleteAllOrderResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp(pad2.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET massActionReportId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~massActionReportId.ok THEN Fail ELSE
    LET noNotAffectedOrders == ReadUIntLE(massActionReportId.rest, 2) IN IF ~noNotAffectedOrders.ok THEN Fail ELSE
    LET noAffectedOrders == ReadUIntLE(noNotAffectedOrders.rest, 2) IN IF ~noAffectedOrders.ok THEN Fail ELSE
    LET pad4 == ReadBytes(noAffectedOrders.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET notAffectedOrdersGrpComp == ReadNotAffectedOrdersGrpComp2List(pad4.rest, noNotAffectedOrders.value) IN IF ~notAffectedOrdersGrpComp.ok THEN Fail ELSE
    LET affectedOrdGrpComp == ReadAffectedOrdGrpComp2List(notAffectedOrdersGrpComp.rest, noAffectedOrders.value) IN IF ~affectedOrdGrpComp.ok THEN Fail ELSE
    Ok([ pad2                     |-> pad2.value,
         responseHeaderMeComp     |-> responseHeaderMeComp.value,
         massActionReportId       |-> massActionReportId.value,
         pad4                     |-> pad4.value,
         notAffectedOrdersGrpComp |-> notAffectedOrdersGrpComp.value,
         affectedOrdGrpComp       |-> affectedOrdGrpComp.value ], affectedOrdGrpComp.rest)

ZeroDeleteAllOrderResponse ==
    [ pad2                     |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp     |-> ZeroResponseHeaderMeComp,
      massActionReportId       |-> [i \in 1 .. 8 |-> 0],
      pad4                     |-> [i \in 1 .. 4 |-> 0],
      notAffectedOrdersGrpComp |-> << >>,
      affectedOrdGrpComp       |-> << >> ]

(* Delete All Order Response at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderResponse ==
    { ZeroDeleteAllOrderResponse }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.responseHeaderMeComp = one] : one \in CheckedResponseHeaderMeComp }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.notAffectedOrdersGrpComp = one] : one \in SampleLists(OneNotAffectedOrdersGrpComp2) }
        \cup { [ZeroDeleteAllOrderResponse EXCEPT !.affectedOrdGrpComp = one] : one \in SampleLists(OneAffectedOrdGrpComp2) }

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
(* Delete Order Broadcast: 154 bytes                                       *)
(***************************************************************************)

DeleteOrderBroadcast ==
    [ pad2                  : Sample(2),
      rbcHeaderMeComp       : RbcHeaderMeComp5,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      orderIdSfx            : Sample(4),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      marketSegmentId       : Sample(4),
      partyIdEnteringTrader : Sample(4),
      partyIdSessionId      : Sample(4),
      execRestatementReason : Sample(2),
      partyIdEnteringFirm   : Sample(1),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      side                  : Sample(1),
      fixClOrdId            : Sample(20),
      pad6                  : Sample(6) ]

EncodeDeleteOrderBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp5(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.orderIdSfx
        \o message.cumQty
        \o message.cxlQty
        \o message.marketSegmentId
        \o message.partyIdEnteringTrader
        \o message.partyIdSessionId
        \o message.execRestatementReason
        \o message.partyIdEnteringFirm
        \o message.ordStatus
        \o message.execType
        \o message.side
        \o message.fixClOrdId
        \o message.pad6

DecodeDeleteOrderBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp5(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(execId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(cxlQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(marketSegmentId.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(partyIdEnteringTrader.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(partyIdSessionId.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(execRestatementReason.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET side == ReadBytes(execType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(side.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET pad6 == ReadBytes(fixClOrdId.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         rbcHeaderMeComp       |-> rbcHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         orderIdSfx            |-> orderIdSfx.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         marketSegmentId       |-> marketSegmentId.value,
         partyIdEnteringTrader |-> partyIdEnteringTrader.value,
         partyIdSessionId      |-> partyIdSessionId.value,
         execRestatementReason |-> execRestatementReason.value,
         partyIdEnteringFirm   |-> partyIdEnteringFirm.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         side                  |-> side.value,
         fixClOrdId            |-> fixClOrdId.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroDeleteOrderBroadcast ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp       |-> ZeroRbcHeaderMeComp5,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      partyIdEnteringTrader |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId      |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      partyIdEnteringFirm   |-> [i \in 1 .. 1 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      fixClOrdId            |-> [i \in 1 .. 20 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

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
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroDeleteOrderBroadcast EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Delete Order Nr Response: 114 bytes                                     *)
(***************************************************************************)

DeleteOrderNrResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp5,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      orderIdSfx             : Sample(4),
      cumQty                 : Sample(4),
      cxlQty                 : Sample(4),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      execRestatementReason  : Sample(2) ]

EncodeDeleteOrderNrResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp5(message.nrResponseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.orderIdSfx
        \o message.cumQty
        \o message.cxlQty
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason

DecodeDeleteOrderNrResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp5(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(execId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(cxlQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         orderIdSfx             |-> orderIdSfx.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         execRestatementReason  |-> execRestatementReason.value ], execRestatementReason.rest)

ZeroDeleteOrderNrResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp5,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx             |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      cxlQty                 |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0] ]

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
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderNrResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }

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
    [ pad2                  : Sample(2),
      responseHeaderMeComp  : ResponseHeaderMeComp2,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      orderIdSfx            : Sample(4),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      execRestatementReason : Sample(2) ]

EncodeDeleteOrderResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderMeComp2(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.orderIdSfx
        \o message.cumQty
        \o message.cxlQty
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason

DecodeDeleteOrderResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp2(pad2.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(execId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(cxlQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         responseHeaderMeComp  |-> responseHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         orderIdSfx            |-> orderIdSfx.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         execRestatementReason |-> execRestatementReason.value ], execRestatementReason.rest)

ZeroDeleteOrderResponse ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp  |-> ZeroResponseHeaderMeComp2,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0] ]

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
        \cup { [ZeroDeleteOrderResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }

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
(* Extended Deletion Report: 282 bytes                                     *)
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
      stopPx                 : Sample(8),
      volumeDiscoveryPrice   : Sample(8),
      pegOffsetValueAbs      : Sample(8),
      pegOffsetValuePct      : Sample(8),
      marketSegmentId        : Sample(4),
      orderIdSfx             : Sample(4),
      leavesQty              : Sample(4),
      cumQty                 : Sample(4),
      cxlQty                 : Sample(4),
      orderQty               : Sample(4),
      displayQty             : Sample(4),
      displayLowQty          : Sample(4),
      displayHighQty         : Sample(4),
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
      fixClOrdId             : Sample(20),
      triggered              : Sample(1),
      pad3                   : Sample(3) ]

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
        \o message.stopPx
        \o message.volumeDiscoveryPrice
        \o message.pegOffsetValueAbs
        \o message.pegOffsetValuePct
        \o message.marketSegmentId
        \o message.orderIdSfx
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.orderQty
        \o message.displayQty
        \o message.displayLowQty
        \o message.displayHighQty
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
        \o message.fixClOrdId
        \o message.triggered
        \o message.pad3

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
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET volumeDiscoveryPrice == ReadBytes(stopPx.rest, 8) IN IF ~volumeDiscoveryPrice.ok THEN Fail ELSE
    LET pegOffsetValueAbs == ReadBytes(volumeDiscoveryPrice.rest, 8) IN IF ~pegOffsetValueAbs.ok THEN Fail ELSE
    LET pegOffsetValuePct == ReadBytes(pegOffsetValueAbs.rest, 8) IN IF ~pegOffsetValuePct.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(pegOffsetValuePct.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(cxlQty.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(orderQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayLowQty == ReadBytes(displayQty.rest, 4) IN IF ~displayLowQty.ok THEN Fail ELSE
    LET displayHighQty == ReadBytes(displayLowQty.rest, 4) IN IF ~displayHighQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayHighQty.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
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
    LET fixClOrdId == ReadBytes(freeText4.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET triggered == ReadBytes(fixClOrdId.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET pad3 == ReadBytes(triggered.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         rbcHeaderMeComp        |-> rbcHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         trdRegTsEntryTime      |-> trdRegTsEntryTime.value,
         price                  |-> price.value,
         stopPx                 |-> stopPx.value,
         volumeDiscoveryPrice   |-> volumeDiscoveryPrice.value,
         pegOffsetValueAbs      |-> pegOffsetValueAbs.value,
         pegOffsetValuePct      |-> pegOffsetValuePct.value,
         marketSegmentId        |-> marketSegmentId.value,
         orderIdSfx             |-> orderIdSfx.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         orderQty               |-> orderQty.value,
         displayQty             |-> displayQty.value,
         displayLowQty          |-> displayLowQty.value,
         displayHighQty         |-> displayHighQty.value,
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
         fixClOrdId             |-> fixClOrdId.value,
         triggered              |-> triggered.value,
         pad3                   |-> pad3.value ], pad3.rest)

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
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      volumeDiscoveryPrice   |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValueAbs      |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValuePct      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx             |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      cxlQty                 |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      displayLowQty          |-> [i \in 1 .. 4 |-> 0],
      displayHighQty         |-> [i \in 1 .. 4 |-> 0],
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
      fixClOrdId             |-> [i \in 1 .. 20 |-> 0],
      triggered              |-> [i \in 1 .. 1 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0] ]

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
        \cup { [ZeroExtendedDeletionReport EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.volumeDiscoveryPrice = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.pegOffsetValueAbs = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.pegOffsetValuePct = one] : one \in Sample(8) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.displayLowQty = one] : one \in Sample(4) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.displayHighQty = one] : one \in Sample(4) }
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
        \cup { [ZeroExtendedDeletionReport EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroExtendedDeletionReport EXCEPT !.pad3 = one] : one \in Sample(3) }

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
(* Gateway Response: 50 bytes                                              *)
(***************************************************************************)

GatewayResponse ==
    [ pad2                   : Sample(2),
      responseHeaderComp     : ResponseHeaderComp,
      gatewayId              : Sample(4),
      gatewaySubId           : Sample(4),
      secondaryGatewayId     : Sample(4),
      secondaryGatewaySubId  : Sample(4),
      gatewayStatus          : Sample(1),
      secondaryGatewayStatus : Sample(1),
      sessionMode            : Sample(1),
      tradSesMode            : Sample(1),
      pad4                   : Sample(4) ]

EncodeGatewayResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp(message.responseHeaderComp)
        \o message.gatewayId
        \o message.gatewaySubId
        \o message.secondaryGatewayId
        \o message.secondaryGatewaySubId
        \o message.gatewayStatus
        \o message.secondaryGatewayStatus
        \o message.sessionMode
        \o message.tradSesMode
        \o message.pad4

DecodeGatewayResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET gatewayId == ReadBytes(responseHeaderComp.rest, 4) IN IF ~gatewayId.ok THEN Fail ELSE
    LET gatewaySubId == ReadBytes(gatewayId.rest, 4) IN IF ~gatewaySubId.ok THEN Fail ELSE
    LET secondaryGatewayId == ReadBytes(gatewaySubId.rest, 4) IN IF ~secondaryGatewayId.ok THEN Fail ELSE
    LET secondaryGatewaySubId == ReadBytes(secondaryGatewayId.rest, 4) IN IF ~secondaryGatewaySubId.ok THEN Fail ELSE
    LET gatewayStatus == ReadBytes(secondaryGatewaySubId.rest, 1) IN IF ~gatewayStatus.ok THEN Fail ELSE
    LET secondaryGatewayStatus == ReadBytes(gatewayStatus.rest, 1) IN IF ~secondaryGatewayStatus.ok THEN Fail ELSE
    LET sessionMode == ReadBytes(secondaryGatewayStatus.rest, 1) IN IF ~sessionMode.ok THEN Fail ELSE
    LET tradSesMode == ReadBytes(sessionMode.rest, 1) IN IF ~tradSesMode.ok THEN Fail ELSE
    LET pad4 == ReadBytes(tradSesMode.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         responseHeaderComp     |-> responseHeaderComp.value,
         gatewayId              |-> gatewayId.value,
         gatewaySubId           |-> gatewaySubId.value,
         secondaryGatewayId     |-> secondaryGatewayId.value,
         secondaryGatewaySubId  |-> secondaryGatewaySubId.value,
         gatewayStatus          |-> gatewayStatus.value,
         secondaryGatewayStatus |-> secondaryGatewayStatus.value,
         sessionMode            |-> sessionMode.value,
         tradSesMode            |-> tradSesMode.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroGatewayResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp     |-> ZeroResponseHeaderComp,
      gatewayId              |-> [i \in 1 .. 4 |-> 0],
      gatewaySubId           |-> [i \in 1 .. 4 |-> 0],
      secondaryGatewayId     |-> [i \in 1 .. 4 |-> 0],
      secondaryGatewaySubId  |-> [i \in 1 .. 4 |-> 0],
      gatewayStatus          |-> [i \in 1 .. 1 |-> 0],
      secondaryGatewayStatus |-> [i \in 1 .. 1 |-> 0],
      sessionMode            |-> [i \in 1 .. 1 |-> 0],
      tradSesMode            |-> [i \in 1 .. 1 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Gateway Response at zero, then each field in turn at the values it is checked at *)
CheckedGatewayResponse ==
    { ZeroGatewayResponse }
        \cup { [ZeroGatewayResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroGatewayResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp }
        \cup { [ZeroGatewayResponse EXCEPT !.gatewayId = one] : one \in Sample(4) }
        \cup { [ZeroGatewayResponse EXCEPT !.gatewaySubId = one] : one \in Sample(4) }
        \cup { [ZeroGatewayResponse EXCEPT !.secondaryGatewayId = one] : one \in Sample(4) }
        \cup { [ZeroGatewayResponse EXCEPT !.secondaryGatewaySubId = one] : one \in Sample(4) }
        \cup { [ZeroGatewayResponse EXCEPT !.gatewayStatus = one] : one \in Sample(1) }
        \cup { [ZeroGatewayResponse EXCEPT !.secondaryGatewayStatus = one] : one \in Sample(1) }
        \cup { [ZeroGatewayResponse EXCEPT !.sessionMode = one] : one \in Sample(1) }
        \cup { [ZeroGatewayResponse EXCEPT !.tradSesMode = one] : one \in Sample(1) }
        \cup { [ZeroGatewayResponse EXCEPT !.pad4 = one] : one \in Sample(4) }

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
      responseHeaderComp     : ResponseHeaderComp2,
      lastEntityProcessed    : Sample(16),
      pad6                   : Sample(6),
      enrichmentRulesGrpComp : SampleLists(OneEnrichmentRulesGrpComp) ]

EncodeInquireEnrichmentRuleIdListResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp2(message.responseHeaderComp)
        \o message.lastEntityProcessed
        \o EncodeUIntLE(Len(message.enrichmentRulesGrpComp), 2)
        \o message.pad6
        \o EncodeEnrichmentRulesGrpCompList(message.enrichmentRulesGrpComp)

DecodeInquireEnrichmentRuleIdListResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp2(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
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
      responseHeaderComp     |-> ZeroResponseHeaderComp2,
      lastEntityProcessed    |-> [i \in 1 .. 16 |-> 0],
      pad6                   |-> [i \in 1 .. 6 |-> 0],
      enrichmentRulesGrpComp |-> << >> ]

(* Inquire Enrichment Rule Id List Response at zero, then each field in turn at the values it is checked at *)
CheckedInquireEnrichmentRuleIdListResponse ==
    { ZeroInquireEnrichmentRuleIdListResponse }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp2 }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroInquireEnrichmentRuleIdListResponse EXCEPT !.enrichmentRulesGrpComp = one] : one \in SampleLists(OneEnrichmentRulesGrpComp) }

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
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp3,
      pad6               : Sample(6),
      sessionsGrpComp    : SampleLists(OneSessionsGrpComp) ]

EncodeInquireSessionListResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp3(message.responseHeaderComp)
        \o EncodeUIntLE(Len(message.sessionsGrpComp), 2)
        \o message.pad6
        \o EncodeSessionsGrpCompList(message.sessionsGrpComp)

DecodeInquireSessionListResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp3(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET noSessions == ReadUIntLE(responseHeaderComp.rest, 2) IN IF ~noSessions.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noSessions.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET sessionsGrpComp == ReadSessionsGrpCompList(pad6.rest, noSessions.value) IN IF ~sessionsGrpComp.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value,
         pad6               |-> pad6.value,
         sessionsGrpComp    |-> sessionsGrpComp.value ], sessionsGrpComp.rest)

ZeroInquireSessionListResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp3,
      pad6               |-> [i \in 1 .. 6 |-> 0],
      sessionsGrpComp    |-> << >> ]

(* Inquire Session List Response at zero, then each field in turn at the values it is checked at *)
CheckedInquireSessionListResponse ==
    { ZeroInquireSessionListResponse }
        \cup { [ZeroInquireSessionListResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
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
      responseHeaderComp  : ResponseHeaderComp4,
      lastEntityProcessed : Sample(16),
      pad6                : Sample(6),
      partyDetailsGrpComp : SampleLists(OnePartyDetailsGrpComp) ]

EncodeInquireUserResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp4(message.responseHeaderComp)
        \o message.lastEntityProcessed
        \o EncodeUIntLE(Len(message.partyDetailsGrpComp), 2)
        \o message.pad6
        \o EncodePartyDetailsGrpCompList(message.partyDetailsGrpComp)

DecodeInquireUserResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp4(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
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
      responseHeaderComp  |-> ZeroResponseHeaderComp4,
      lastEntityProcessed |-> [i \in 1 .. 16 |-> 0],
      pad6                |-> [i \in 1 .. 6 |-> 0],
      partyDetailsGrpComp |-> << >> ]

(* Inquire User Response at zero, then each field in turn at the values it is checked at *)
CheckedInquireUserResponse ==
    { ZeroInquireUserResponse }
        \cup { [ZeroInquireUserResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireUserResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp4 }
        \cup { [ZeroInquireUserResponse EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }
        \cup { [ZeroInquireUserResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroInquireUserResponse EXCEPT !.partyDetailsGrpComp = one] : one \in SampleLists(OnePartyDetailsGrpComp) }

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
(* Logon Response: 90 bytes                                                *)
(***************************************************************************)

LogonResponse ==
    [ pad2                    : Sample(2),
      responseHeaderComp      : ResponseHeaderComp5,
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
        \o EncodeResponseHeaderComp5(message.responseHeaderComp)
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
    LET responseHeaderComp == DecodeResponseHeaderComp5(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
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
      responseHeaderComp      |-> ZeroResponseHeaderComp5,
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
        \cup { [ZeroLogonResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp5 }
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
(* Logout Response: 26 bytes                                               *)
(***************************************************************************)

LogoutResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp6 ]

EncodeLogoutResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp6(message.responseHeaderComp)

DecodeLogoutResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp6(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value ], responseHeaderComp.rest)

ZeroLogoutResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp6 ]

(* Logout Response at zero, then each field in turn at the values it is checked at *)
CheckedLogoutResponse ==
    { ZeroLogoutResponse }
        \cup { [ZeroLogoutResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogoutResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp6 }

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
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp6,
      quoteId                : Sample(8),
      quoteResponseId        : Sample(8),
      marketSegmentId        : Sample(4),
      pad3                   : Sample(3),
      quoteEntryAckGrpComp   : SampleLists(OneQuoteEntryAckGrpComp) ]

EncodeMassQuoteResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp6(message.nrResponseHeaderMeComp)
        \o message.quoteId
        \o message.quoteResponseId
        \o message.marketSegmentId
        \o EncodeUIntBE(Len(message.quoteEntryAckGrpComp), 1)
        \o message.pad3
        \o EncodeQuoteEntryAckGrpCompList(message.quoteEntryAckGrpComp)

DecodeMassQuoteResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp6(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteResponseId == ReadBytes(quoteId.rest, 8) IN IF ~quoteResponseId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteResponseId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET noQuoteEntries == ReadUIntBE(marketSegmentId.rest, 1) IN IF ~noQuoteEntries.ok THEN Fail ELSE
    LET pad3 == ReadBytes(noQuoteEntries.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET quoteEntryAckGrpComp == ReadQuoteEntryAckGrpCompList(pad3.rest, noQuoteEntries.value) IN IF ~quoteEntryAckGrpComp.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         quoteId                |-> quoteId.value,
         quoteResponseId        |-> quoteResponseId.value,
         marketSegmentId        |-> marketSegmentId.value,
         pad3                   |-> pad3.value,
         quoteEntryAckGrpComp   |-> quoteEntryAckGrpComp.value ], quoteEntryAckGrpComp.rest)

ZeroMassQuoteResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp6,
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      quoteResponseId        |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0],
      quoteEntryAckGrpComp   |-> << >> ]

(* Mass Quote Response at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteResponse ==
    { ZeroMassQuoteResponse }
        \cup { [ZeroMassQuoteResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp6 }
        \cup { [ZeroMassQuoteResponse EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.quoteResponseId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroMassQuoteResponse EXCEPT !.quoteEntryAckGrpComp = one] : one \in SampleLists(OneQuoteEntryAckGrpComp) }

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
(* Modify Order Nr Response: 138 bytes                                     *)
(***************************************************************************)

ModifyOrderNrResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp7,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      stopPx                 : Sample(8),
      orderIdSfx             : Sample(4),
      leavesQty              : Sample(4),
      cumQty                 : Sample(4),
      cxlQty                 : Sample(4),
      displayQty             : Sample(4),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      execRestatementReason  : Sample(2),
      crossedIndicator       : Sample(1),
      triggered              : Sample(1),
      pad6                   : Sample(6) ]

EncodeModifyOrderNrResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp7(message.nrResponseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.stopPx
        \o message.orderIdSfx
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.displayQty
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.crossedIndicator
        \o message.triggered
        \o message.pad6

DecodeModifyOrderNrResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp7(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET stopPx == ReadBytes(execId.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(stopPx.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(cxlQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(displayQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(execRestatementReason.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET triggered == ReadBytes(crossedIndicator.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET pad6 == ReadBytes(triggered.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         stopPx                 |-> stopPx.value,
         orderIdSfx             |-> orderIdSfx.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         displayQty             |-> displayQty.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         execRestatementReason  |-> execRestatementReason.value,
         crossedIndicator       |-> crossedIndicator.value,
         triggered              |-> triggered.value,
         pad6                   |-> pad6.value ], pad6.rest)

ZeroModifyOrderNrResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp7,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx             |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      cxlQty                 |-> [i \in 1 .. 4 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0],
      crossedIndicator       |-> [i \in 1 .. 1 |-> 0],
      triggered              |-> [i \in 1 .. 1 |-> 0],
      pad6                   |-> [i \in 1 .. 6 |-> 0] ]

(* Modify Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderNrResponse ==
    { ZeroModifyOrderNrResponse }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp7 }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderNrResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Modify Order Response: 162 bytes                                        *)
(***************************************************************************)

ModifyOrderResponse ==
    [ pad2                  : Sample(2),
      responseHeaderMeComp  : ResponseHeaderMeComp3,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      stopPx                : Sample(8),
      trdRegTsTimePriority  : Sample(8),
      orderIdSfx            : Sample(4),
      leavesQty             : Sample(4),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      displayQty            : Sample(4),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      execRestatementReason : Sample(2),
      crossedIndicator      : Sample(1),
      triggered             : Sample(1),
      pad6                  : Sample(6) ]

EncodeModifyOrderResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderMeComp3(message.responseHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.stopPx
        \o message.trdRegTsTimePriority
        \o message.orderIdSfx
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.displayQty
        \o message.ordStatus
        \o message.execType
        \o message.execRestatementReason
        \o message.crossedIndicator
        \o message.triggered
        \o message.pad6

DecodeModifyOrderResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderMeComp == DecodeResponseHeaderMeComp3(pad2.rest) IN IF ~responseHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(responseHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET stopPx == ReadBytes(execId.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(stopPx.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(trdRegTsTimePriority.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(cxlQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(displayQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(execType.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(execRestatementReason.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET triggered == ReadBytes(crossedIndicator.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET pad6 == ReadBytes(triggered.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         responseHeaderMeComp  |-> responseHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         stopPx                |-> stopPx.value,
         trdRegTsTimePriority  |-> trdRegTsTimePriority.value,
         orderIdSfx            |-> orderIdSfx.value,
         leavesQty             |-> leavesQty.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         displayQty            |-> displayQty.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         execRestatementReason |-> execRestatementReason.value,
         crossedIndicator      |-> crossedIndicator.value,
         triggered             |-> triggered.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroModifyOrderResponse ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp  |-> ZeroResponseHeaderMeComp3,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority  |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      crossedIndicator      |-> [i \in 1 .. 1 |-> 0],
      triggered             |-> [i \in 1 .. 1 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

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
        \cup { [ZeroModifyOrderResponse EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* New Order Nr Response: 106 bytes                                        *)
(***************************************************************************)

NewOrderNrResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp8,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      orderIdSfx             : Sample(4),
      ordStatus              : Sample(1),
      execType               : Sample(1),
      execRestatementReason  : Sample(2),
      crossedIndicator       : Sample(1),
      triggered              : Sample(1),
      pad6                   : Sample(6) ]

EncodeNewOrderNrResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp8(message.nrResponseHeaderMeComp)
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
        \o message.pad6

DecodeNewOrderNrResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp8(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
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
    LET pad6 == ReadBytes(triggered.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         securityId             |-> securityId.value,
         execId                 |-> execId.value,
         orderIdSfx             |-> orderIdSfx.value,
         ordStatus              |-> ordStatus.value,
         execType               |-> execType.value,
         execRestatementReason  |-> execRestatementReason.value,
         crossedIndicator       |-> crossedIndicator.value,
         triggered              |-> triggered.value,
         pad6                   |-> pad6.value ], pad6.rest)

ZeroNewOrderNrResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp8,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx             |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason  |-> [i \in 1 .. 2 |-> 0],
      crossedIndicator       |-> [i \in 1 .. 1 |-> 0],
      triggered              |-> [i \in 1 .. 1 |-> 0],
      pad6                   |-> [i \in 1 .. 6 |-> 0] ]

(* New Order Nr Response at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderNrResponse ==
    { ZeroNewOrderNrResponse }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderNrResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp8 }
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
        \cup { [ZeroNewOrderNrResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* New Order Response: 138 bytes                                           *)
(***************************************************************************)

NewOrderResponse ==
    [ pad2                  : Sample(2),
      responseHeaderMeComp  : ResponseHeaderMeComp4,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      trdRegTsEntryTime     : Sample(8),
      trdRegTsTimePriority  : Sample(8),
      orderIdSfx            : Sample(4),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      execRestatementReason : Sample(2),
      crossedIndicator      : Sample(1),
      triggered             : Sample(1),
      pad6                  : Sample(6) ]

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
        \o message.pad6

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
    LET pad6 == ReadBytes(triggered.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         responseHeaderMeComp  |-> responseHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         trdRegTsEntryTime     |-> trdRegTsEntryTime.value,
         trdRegTsTimePriority  |-> trdRegTsTimePriority.value,
         orderIdSfx            |-> orderIdSfx.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         execRestatementReason |-> execRestatementReason.value,
         crossedIndicator      |-> crossedIndicator.value,
         triggered             |-> triggered.value,
         pad6                  |-> pad6.value ], pad6.rest)

ZeroNewOrderResponse ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp  |-> ZeroResponseHeaderMeComp4,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority  |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      crossedIndicator      |-> [i \in 1 .. 1 |-> 0],
      triggered             |-> [i \in 1 .. 1 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

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
        \cup { [ZeroNewOrderResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Fills Grp Comp: 24 bytes                                                *)
(***************************************************************************)

FillsGrpComp ==
    [ fillPx           : Sample(8),
      fillQty          : Sample(4),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad3             : Sample(3) ]

EncodeFillsGrpComp(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad3

DecodeFillsGrpComp(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad3 == ReadBytes(fillLiquidityInd.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad3             |-> pad3.value ], pad3.rest)

ZeroFillsGrpComp ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 4 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad3             |-> [i \in 1 .. 3 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp ==
    { ZeroFillsGrpComp }
        \cup { [ZeroFillsGrpComp EXCEPT !.fillPx = one] : one \in Sample(8) }
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
(* Order Exec Notification                                                 *)
(***************************************************************************)

OrderExecNotification ==
    [ pad2                  : Sample(2),
      rbcHeaderMeComp       : RbcHeaderMeComp7,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      marketSegmentId       : Sample(4),
      orderIdSfx            : Sample(4),
      leavesQty             : Sample(4),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      displayQty            : Sample(4),
      execRestatementReason : Sample(2),
      side                  : Sample(1),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      matchType             : Sample(1),
      triggered             : Sample(1),
      crossedIndicator      : Sample(1),
      fixClOrdId            : Sample(20),
      pad3                  : Sample(3),
      fillsGrpComp          : SampleLists(OneFillsGrpComp) ]

EncodeOrderExecNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp7(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.marketSegmentId
        \o message.orderIdSfx
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.displayQty
        \o message.execRestatementReason
        \o message.side
        \o message.ordStatus
        \o message.execType
        \o message.matchType
        \o message.triggered
        \o message.crossedIndicator
        \o message.fixClOrdId
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.pad3
        \o EncodeFillsGrpCompList(message.fillsGrpComp)

DecodeOrderExecNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp7(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(execId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(cxlQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(displayQty.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET side == ReadBytes(execRestatementReason.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(side.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET matchType == ReadBytes(execType.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET triggered == ReadBytes(matchType.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(triggered.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(crossedIndicator.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(fixClOrdId.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET pad3 == ReadBytes(noFills.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpCompList(pad3.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         rbcHeaderMeComp       |-> rbcHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         marketSegmentId       |-> marketSegmentId.value,
         orderIdSfx            |-> orderIdSfx.value,
         leavesQty             |-> leavesQty.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         displayQty            |-> displayQty.value,
         execRestatementReason |-> execRestatementReason.value,
         side                  |-> side.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         matchType             |-> matchType.value,
         triggered             |-> triggered.value,
         crossedIndicator      |-> crossedIndicator.value,
         fixClOrdId            |-> fixClOrdId.value,
         pad3                  |-> pad3.value,
         fillsGrpComp          |-> fillsGrpComp.value ], fillsGrpComp.rest)

ZeroOrderExecNotification ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp       |-> ZeroRbcHeaderMeComp7,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      matchType             |-> [i \in 1 .. 1 |-> 0],
      triggered             |-> [i \in 1 .. 1 |-> 0],
      crossedIndicator      |-> [i \in 1 .. 1 |-> 0],
      fixClOrdId            |-> [i \in 1 .. 20 |-> 0],
      pad3                  |-> [i \in 1 .. 3 |-> 0],
      fillsGrpComp          |-> << >> ]

(* Order Exec Notification at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecNotification ==
    { ZeroOrderExecNotification }
        \cup { [ZeroOrderExecNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp7 }
        \cup { [ZeroOrderExecNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecNotification EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecNotification EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecNotification EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroOrderExecNotification EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp) }

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
(* Fills Grp Comp: 24 bytes                                                *)
(***************************************************************************)

FillsGrpComp2 ==
    [ fillPx           : Sample(8),
      fillQty          : Sample(4),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad3             : Sample(3) ]

EncodeFillsGrpComp2(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad3

DecodeFillsGrpComp2(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad3 == ReadBytes(fillLiquidityInd.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad3             |-> pad3.value ], pad3.rest)

ZeroFillsGrpComp2 ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 4 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad3             |-> [i \in 1 .. 3 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp2 ==
    { ZeroFillsGrpComp2 }
        \cup { [ZeroFillsGrpComp2 EXCEPT !.fillPx = one] : one \in Sample(8) }
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
(* Order Exec Report Broadcast                                             *)
(***************************************************************************)

OrderExecReportBroadcast ==
    [ pad2                   : Sample(2),
      rbcHeaderMeComp        : RbcHeaderMeComp8,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      execId                 : Sample(8),
      trdRegTsEntryTime      : Sample(8),
      trdRegTsTimePriority   : Sample(8),
      price                  : Sample(8),
      stopPx                 : Sample(8),
      volumeDiscoveryPrice   : Sample(8),
      pegOffsetValueAbs      : Sample(8),
      pegOffsetValuePct      : Sample(8),
      marketSegmentId        : Sample(4),
      orderIdSfx             : Sample(4),
      leavesQty              : Sample(4),
      cumQty                 : Sample(4),
      cxlQty                 : Sample(4),
      orderQty               : Sample(4),
      displayQty             : Sample(4),
      displayLowQty          : Sample(4),
      displayHighQty         : Sample(4),
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
      matchType              : Sample(1),
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
      fixClOrdId             : Sample(20),
      triggered              : Sample(1),
      crossedIndicator       : Sample(1),
      pad7                   : Sample(7),
      fillsGrpComp           : SampleLists(OneFillsGrpComp2) ]

EncodeOrderExecReportBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp8(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.trdRegTsEntryTime
        \o message.trdRegTsTimePriority
        \o message.price
        \o message.stopPx
        \o message.volumeDiscoveryPrice
        \o message.pegOffsetValueAbs
        \o message.pegOffsetValuePct
        \o message.marketSegmentId
        \o message.orderIdSfx
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.orderQty
        \o message.displayQty
        \o message.displayLowQty
        \o message.displayHighQty
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
        \o message.matchType
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
        \o message.fixClOrdId
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.triggered
        \o message.crossedIndicator
        \o message.pad7
        \o EncodeFillsGrpComp2List(message.fillsGrpComp)

DecodeOrderExecReportBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp8(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET trdRegTsEntryTime == ReadBytes(execId.rest, 8) IN IF ~trdRegTsEntryTime.ok THEN Fail ELSE
    LET trdRegTsTimePriority == ReadBytes(trdRegTsEntryTime.rest, 8) IN IF ~trdRegTsTimePriority.ok THEN Fail ELSE
    LET price == ReadBytes(trdRegTsTimePriority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET volumeDiscoveryPrice == ReadBytes(stopPx.rest, 8) IN IF ~volumeDiscoveryPrice.ok THEN Fail ELSE
    LET pegOffsetValueAbs == ReadBytes(volumeDiscoveryPrice.rest, 8) IN IF ~pegOffsetValueAbs.ok THEN Fail ELSE
    LET pegOffsetValuePct == ReadBytes(pegOffsetValueAbs.rest, 8) IN IF ~pegOffsetValuePct.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(pegOffsetValuePct.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET orderQty == ReadBytes(cxlQty.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(orderQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayLowQty == ReadBytes(displayQty.rest, 4) IN IF ~displayLowQty.ok THEN Fail ELSE
    LET displayHighQty == ReadBytes(displayLowQty.rest, 4) IN IF ~displayHighQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayHighQty.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(expireDate.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET partyIdExecutingUnit == ReadBytes(matchInstCrossId.rest, 4) IN IF ~partyIdExecutingUnit.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(partyIdExecutingUnit.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET partyIdExecutingTrader == ReadBytes(partyIdSessionId.rest, 4) IN IF ~partyIdExecutingTrader.ok THEN Fail ELSE
    LET partyIdEnteringTrader == ReadBytes(partyIdExecutingTrader.rest, 4) IN IF ~partyIdEnteringTrader.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(partyIdEnteringTrader.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET partyIdEnteringFirm == ReadBytes(execRestatementReason.rest, 1) IN IF ~partyIdEnteringFirm.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(partyIdEnteringFirm.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET matchType == ReadBytes(execType.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET side == ReadBytes(matchType.rest, 1) IN IF ~side.ok THEN Fail ELSE
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
    LET fixClOrdId == ReadBytes(freeText4.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(fixClOrdId.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET triggered == ReadBytes(noFills.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(triggered.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET pad7 == ReadBytes(crossedIndicator.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpComp2List(pad7.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
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
         stopPx                 |-> stopPx.value,
         volumeDiscoveryPrice   |-> volumeDiscoveryPrice.value,
         pegOffsetValueAbs      |-> pegOffsetValueAbs.value,
         pegOffsetValuePct      |-> pegOffsetValuePct.value,
         marketSegmentId        |-> marketSegmentId.value,
         orderIdSfx             |-> orderIdSfx.value,
         leavesQty              |-> leavesQty.value,
         cumQty                 |-> cumQty.value,
         cxlQty                 |-> cxlQty.value,
         orderQty               |-> orderQty.value,
         displayQty             |-> displayQty.value,
         displayLowQty          |-> displayLowQty.value,
         displayHighQty         |-> displayHighQty.value,
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
         matchType              |-> matchType.value,
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
         fixClOrdId             |-> fixClOrdId.value,
         triggered              |-> triggered.value,
         crossedIndicator       |-> crossedIndicator.value,
         pad7                   |-> pad7.value,
         fillsGrpComp           |-> fillsGrpComp.value ], fillsGrpComp.rest)

ZeroOrderExecReportBroadcast ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp        |-> ZeroRbcHeaderMeComp8,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      execId                 |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime      |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority   |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      stopPx                 |-> [i \in 1 .. 8 |-> 0],
      volumeDiscoveryPrice   |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValueAbs      |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValuePct      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx             |-> [i \in 1 .. 4 |-> 0],
      leavesQty              |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      cxlQty                 |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      displayLowQty          |-> [i \in 1 .. 4 |-> 0],
      displayHighQty         |-> [i \in 1 .. 4 |-> 0],
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
      matchType              |-> [i \in 1 .. 1 |-> 0],
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
      fixClOrdId             |-> [i \in 1 .. 20 |-> 0],
      triggered              |-> [i \in 1 .. 1 |-> 0],
      crossedIndicator       |-> [i \in 1 .. 1 |-> 0],
      pad7                   |-> [i \in 1 .. 7 |-> 0],
      fillsGrpComp           |-> << >> ]

(* Order Exec Report Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecReportBroadcast ==
    { ZeroOrderExecReportBroadcast }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp8 }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.trdRegTsEntryTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.trdRegTsTimePriority = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.volumeDiscoveryPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pegOffsetValueAbs = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pegOffsetValuePct = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.displayLowQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.displayHighQty = one] : one \in Sample(4) }
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
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.exDestinationType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroOrderExecReportBroadcast EXCEPT !.fillsGrpComp = one] : one \in SampleLists(OneFillsGrpComp2) }

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
(* Fills Grp Comp: 24 bytes                                                *)
(***************************************************************************)

FillsGrpComp3 ==
    [ fillPx           : Sample(8),
      fillQty          : Sample(4),
      fillMatchId      : Sample(4),
      fillExecId       : Sample(4),
      fillLiquidityInd : Sample(1),
      pad3             : Sample(3) ]

EncodeFillsGrpComp3(message) ==
    message.fillPx
        \o message.fillQty
        \o message.fillMatchId
        \o message.fillExecId
        \o message.fillLiquidityInd
        \o message.pad3

DecodeFillsGrpComp3(bytes) ==
    LET fillPx == ReadBytes(bytes, 8) IN IF ~fillPx.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillPx.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillMatchId == ReadBytes(fillQty.rest, 4) IN IF ~fillMatchId.ok THEN Fail ELSE
    LET fillExecId == ReadBytes(fillMatchId.rest, 4) IN IF ~fillExecId.ok THEN Fail ELSE
    LET fillLiquidityInd == ReadBytes(fillExecId.rest, 1) IN IF ~fillLiquidityInd.ok THEN Fail ELSE
    LET pad3 == ReadBytes(fillLiquidityInd.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ fillPx           |-> fillPx.value,
         fillQty          |-> fillQty.value,
         fillMatchId      |-> fillMatchId.value,
         fillExecId       |-> fillExecId.value,
         fillLiquidityInd |-> fillLiquidityInd.value,
         pad3             |-> pad3.value ], pad3.rest)

ZeroFillsGrpComp3 ==
    [ fillPx           |-> [i \in 1 .. 8 |-> 0],
      fillQty          |-> [i \in 1 .. 4 |-> 0],
      fillMatchId      |-> [i \in 1 .. 4 |-> 0],
      fillExecId       |-> [i \in 1 .. 4 |-> 0],
      fillLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      pad3             |-> [i \in 1 .. 3 |-> 0] ]

(* Fills Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedFillsGrpComp3 ==
    { ZeroFillsGrpComp3 }
        \cup { [ZeroFillsGrpComp3 EXCEPT !.fillPx = one] : one \in Sample(8) }
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
(* Order Exec Response                                                     *)
(***************************************************************************)

OrderExecResponse ==
    [ pad2                  : Sample(2),
      responseHeaderMeComp  : ResponseHeaderMeComp5,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      trdRegTsEntryTime     : Sample(8),
      trdRegTsTimePriority  : Sample(8),
      marketSegmentId       : Sample(4),
      orderIdSfx            : Sample(4),
      leavesQty             : Sample(4),
      cumQty                : Sample(4),
      cxlQty                : Sample(4),
      displayQty            : Sample(4),
      execRestatementReason : Sample(2),
      side                  : Sample(1),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      matchType             : Sample(1),
      triggered             : Sample(1),
      crossedIndicator      : Sample(1),
      pad7                  : Sample(7),
      fillsGrpComp          : SampleLists(OneFillsGrpComp3) ]

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
        \o message.marketSegmentId
        \o message.orderIdSfx
        \o message.leavesQty
        \o message.cumQty
        \o message.cxlQty
        \o message.displayQty
        \o message.execRestatementReason
        \o message.side
        \o message.ordStatus
        \o message.execType
        \o message.matchType
        \o message.triggered
        \o message.crossedIndicator
        \o EncodeUIntBE(Len(message.fillsGrpComp), 1)
        \o message.pad7
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
    LET marketSegmentId == ReadBytes(trdRegTsTimePriority.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET cumQty == ReadBytes(leavesQty.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET cxlQty == ReadBytes(cumQty.rest, 4) IN IF ~cxlQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(cxlQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(displayQty.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET side == ReadBytes(execRestatementReason.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(side.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET matchType == ReadBytes(execType.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET triggered == ReadBytes(matchType.rest, 1) IN IF ~triggered.ok THEN Fail ELSE
    LET crossedIndicator == ReadBytes(triggered.rest, 1) IN IF ~crossedIndicator.ok THEN Fail ELSE
    LET noFills == ReadUIntBE(crossedIndicator.rest, 1) IN IF ~noFills.ok THEN Fail ELSE
    LET pad7 == ReadBytes(noFills.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET fillsGrpComp == ReadFillsGrpComp3List(pad7.rest, noFills.value) IN IF ~fillsGrpComp.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         responseHeaderMeComp  |-> responseHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         trdRegTsEntryTime     |-> trdRegTsEntryTime.value,
         trdRegTsTimePriority  |-> trdRegTsTimePriority.value,
         marketSegmentId       |-> marketSegmentId.value,
         orderIdSfx            |-> orderIdSfx.value,
         leavesQty             |-> leavesQty.value,
         cumQty                |-> cumQty.value,
         cxlQty                |-> cxlQty.value,
         displayQty            |-> displayQty.value,
         execRestatementReason |-> execRestatementReason.value,
         side                  |-> side.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         matchType             |-> matchType.value,
         triggered             |-> triggered.value,
         crossedIndicator      |-> crossedIndicator.value,
         pad7                  |-> pad7.value,
         fillsGrpComp          |-> fillsGrpComp.value ], fillsGrpComp.rest)

ZeroOrderExecResponse ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      responseHeaderMeComp  |-> ZeroResponseHeaderMeComp5,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      trdRegTsEntryTime     |-> [i \in 1 .. 8 |-> 0],
      trdRegTsTimePriority  |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      leavesQty             |-> [i \in 1 .. 4 |-> 0],
      cumQty                |-> [i \in 1 .. 4 |-> 0],
      cxlQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      matchType             |-> [i \in 1 .. 1 |-> 0],
      triggered             |-> [i \in 1 .. 1 |-> 0],
      crossedIndicator      |-> [i \in 1 .. 1 |-> 0],
      pad7                  |-> [i \in 1 .. 7 |-> 0],
      fillsGrpComp          |-> << >> ]

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
        \cup { [ZeroOrderExecResponse EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.cxlQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecResponse EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecResponse EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.triggered = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.crossedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecResponse EXCEPT !.pad7 = one] : one \in Sample(7) }
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
      rbcHeaderMeComp              : RbcHeaderMeComp9,
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
        \o EncodeRbcHeaderMeComp9(message.rbcHeaderMeComp)
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
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp9(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
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
      rbcHeaderMeComp              |-> ZeroRbcHeaderMeComp9,
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
        \cup { [ZeroQuoteActivationNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp9 }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.partyIdEnteringTrader = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.partyIdEnteringFirm = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.massActionType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.massActionReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroQuoteActivationNotification EXCEPT !.notAffectedSecuritiesGrpComp = one] : one \in SampleLists(OneNotAffectedSecuritiesGrpComp3) }

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
      nrResponseHeaderMeComp       : NrResponseHeaderMeComp9,
      massActionReportId           : Sample(8),
      pad6                         : Sample(6),
      notAffectedSecuritiesGrpComp : SampleLists(OneNotAffectedSecuritiesGrpComp4) ]

EncodeQuoteActivationResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp9(message.nrResponseHeaderMeComp)
        \o message.massActionReportId
        \o EncodeUIntLE(Len(message.notAffectedSecuritiesGrpComp), 2)
        \o message.pad6
        \o EncodeNotAffectedSecuritiesGrpComp4List(message.notAffectedSecuritiesGrpComp)

DecodeQuoteActivationResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp9(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
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
      nrResponseHeaderMeComp       |-> ZeroNrResponseHeaderMeComp9,
      massActionReportId           |-> [i \in 1 .. 8 |-> 0],
      pad6                         |-> [i \in 1 .. 6 |-> 0],
      notAffectedSecuritiesGrpComp |-> << >> ]

(* Quote Activation Response at zero, then each field in turn at the values it is checked at *)
CheckedQuoteActivationResponse ==
    { ZeroQuoteActivationResponse }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp9 }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.massActionReportId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroQuoteActivationResponse EXCEPT !.notAffectedSecuritiesGrpComp = one] : one \in SampleLists(OneNotAffectedSecuritiesGrpComp4) }

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
(* Quote Event Grp Comp: 40 bytes                                          *)
(***************************************************************************)

QuoteEventGrpComp ==
    [ securityId             : Sample(8),
      quoteEventPx           : Sample(8),
      quoteMsgId             : Sample(8),
      quoteEventMatchId      : Sample(4),
      quoteEventExecId       : Sample(4),
      quoteEventQty          : Sample(4),
      quoteEventType         : Sample(1),
      quoteEventSide         : Sample(1),
      quoteEventLiquidityInd : Sample(1),
      quoteEventReason       : Sample(1) ]

EncodeQuoteEventGrpComp(message) ==
    message.securityId
        \o message.quoteEventPx
        \o message.quoteMsgId
        \o message.quoteEventMatchId
        \o message.quoteEventExecId
        \o message.quoteEventQty
        \o message.quoteEventType
        \o message.quoteEventSide
        \o message.quoteEventLiquidityInd
        \o message.quoteEventReason

DecodeQuoteEventGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteEventPx == ReadBytes(securityId.rest, 8) IN IF ~quoteEventPx.ok THEN Fail ELSE
    LET quoteMsgId == ReadBytes(quoteEventPx.rest, 8) IN IF ~quoteMsgId.ok THEN Fail ELSE
    LET quoteEventMatchId == ReadBytes(quoteMsgId.rest, 4) IN IF ~quoteEventMatchId.ok THEN Fail ELSE
    LET quoteEventExecId == ReadBytes(quoteEventMatchId.rest, 4) IN IF ~quoteEventExecId.ok THEN Fail ELSE
    LET quoteEventQty == ReadBytes(quoteEventExecId.rest, 4) IN IF ~quoteEventQty.ok THEN Fail ELSE
    LET quoteEventType == ReadBytes(quoteEventQty.rest, 1) IN IF ~quoteEventType.ok THEN Fail ELSE
    LET quoteEventSide == ReadBytes(quoteEventType.rest, 1) IN IF ~quoteEventSide.ok THEN Fail ELSE
    LET quoteEventLiquidityInd == ReadBytes(quoteEventSide.rest, 1) IN IF ~quoteEventLiquidityInd.ok THEN Fail ELSE
    LET quoteEventReason == ReadBytes(quoteEventLiquidityInd.rest, 1) IN IF ~quoteEventReason.ok THEN Fail ELSE
    Ok([ securityId             |-> securityId.value,
         quoteEventPx           |-> quoteEventPx.value,
         quoteMsgId             |-> quoteMsgId.value,
         quoteEventMatchId      |-> quoteEventMatchId.value,
         quoteEventExecId       |-> quoteEventExecId.value,
         quoteEventQty          |-> quoteEventQty.value,
         quoteEventType         |-> quoteEventType.value,
         quoteEventSide         |-> quoteEventSide.value,
         quoteEventLiquidityInd |-> quoteEventLiquidityInd.value,
         quoteEventReason       |-> quoteEventReason.value ], quoteEventReason.rest)

ZeroQuoteEventGrpComp ==
    [ securityId             |-> [i \in 1 .. 8 |-> 0],
      quoteEventPx           |-> [i \in 1 .. 8 |-> 0],
      quoteMsgId             |-> [i \in 1 .. 8 |-> 0],
      quoteEventMatchId      |-> [i \in 1 .. 4 |-> 0],
      quoteEventExecId       |-> [i \in 1 .. 4 |-> 0],
      quoteEventQty          |-> [i \in 1 .. 4 |-> 0],
      quoteEventType         |-> [i \in 1 .. 1 |-> 0],
      quoteEventSide         |-> [i \in 1 .. 1 |-> 0],
      quoteEventLiquidityInd |-> [i \in 1 .. 1 |-> 0],
      quoteEventReason       |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Event Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEventGrpComp ==
    { ZeroQuoteEventGrpComp }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteMsgId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventMatchId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventExecId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventSide = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroQuoteEventGrpComp EXCEPT !.quoteEventReason = one] : one \in Sample(1) }

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
      rbcHeaderMeComp   : RbcHeaderMeComp10,
      execId            : Sample(8),
      marketSegmentId   : Sample(4),
      pad3              : Sample(3),
      quoteEventGrpComp : SampleLists(OneQuoteEventGrpComp) ]

EncodeQuoteExecutionReport(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp10(message.rbcHeaderMeComp)
        \o message.execId
        \o message.marketSegmentId
        \o EncodeUIntBE(Len(message.quoteEventGrpComp), 1)
        \o message.pad3
        \o EncodeQuoteEventGrpCompList(message.quoteEventGrpComp)

DecodeQuoteExecutionReport(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp10(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
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
      rbcHeaderMeComp   |-> ZeroRbcHeaderMeComp10,
      execId            |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      pad3              |-> [i \in 1 .. 3 |-> 0],
      quoteEventGrpComp |-> << >> ]

(* Quote Execution Report at zero, then each field in turn at the values it is checked at *)
CheckedQuoteExecutionReport ==
    { ZeroQuoteExecutionReport }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp10 }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroQuoteExecutionReport EXCEPT !.quoteEventGrpComp = one] : one \in SampleLists(OneQuoteEventGrpComp) }

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
(* Rfq Broadcast: 90 bytes                                                 *)
(***************************************************************************)

RfqBroadcast ==
    [ pad2               : Sample(2),
      rbcHeaderMeComp    : RbcHeaderMeComp11,
      securityId         : Sample(8),
      execId             : Sample(8),
      marketSegmentId    : Sample(4),
      orderQty           : Sample(4),
      side               : Sample(1),
      partyExecutingFirm : Sample(5),
      pad2v2             : Sample(2) ]

EncodeRfqBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp11(message.rbcHeaderMeComp)
        \o message.securityId
        \o message.execId
        \o message.marketSegmentId
        \o message.orderQty
        \o message.side
        \o message.partyExecutingFirm
        \o message.pad2v2

DecodeRfqBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp11(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(execId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(partyExecutingFirm.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         rbcHeaderMeComp    |-> rbcHeaderMeComp.value,
         securityId         |-> securityId.value,
         execId             |-> execId.value,
         marketSegmentId    |-> marketSegmentId.value,
         orderQty           |-> orderQty.value,
         side               |-> side.value,
         partyExecutingFirm |-> partyExecutingFirm.value,
         pad2v2             |-> pad2v2.value ], pad2v2.rest)

ZeroRfqBroadcast ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp    |-> ZeroRbcHeaderMeComp11,
      securityId         |-> [i \in 1 .. 8 |-> 0],
      execId             |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm |-> [i \in 1 .. 5 |-> 0],
      pad2v2             |-> [i \in 1 .. 2 |-> 0] ]

(* Rfq Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedRfqBroadcast ==
    { ZeroRfqBroadcast }
        \cup { [ZeroRfqBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp11 }
        \cup { [ZeroRfqBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRfqBroadcast EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroRfqBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRfqBroadcast EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroRfqBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRfqBroadcast EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroRfqBroadcast EXCEPT !.pad2v2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp10 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp10(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp10(bytes) ==
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

ZeroNrResponseHeaderMeComp10 ==
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
CheckedNrResponseHeaderMeComp10 ==
    { ZeroNrResponseHeaderMeComp10 }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp10 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Rfq Response: 66 bytes                                                  *)
(***************************************************************************)

RfqResponse ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp10,
      execId                 : Sample(8) ]

EncodeRfqResponse(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp10(message.nrResponseHeaderMeComp)
        \o message.execId

DecodeRfqResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp10(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
    LET execId == ReadBytes(nrResponseHeaderMeComp.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    Ok([ pad2                   |-> pad2.value,
         nrResponseHeaderMeComp |-> nrResponseHeaderMeComp.value,
         execId                 |-> execId.value ], execId.rest)

ZeroRfqResponse ==
    [ pad2                   |-> [i \in 1 .. 2 |-> 0],
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp10,
      execId                 |-> [i \in 1 .. 8 |-> 0] ]

(* Rfq Response at zero, then each field in turn at the values it is checked at *)
CheckedRfqResponse ==
    { ZeroRfqResponse }
        \cup { [ZeroRfqResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqResponse EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp10 }
        \cup { [ZeroRfqResponse EXCEPT !.execId = one] : one \in Sample(8) }

(***************************************************************************)
(* Nr Response Header Me Comp: 56 bytes                                    *)
(***************************************************************************)

NrResponseHeaderMeComp11 ==
    [ requestTime     : Sample(8),
      requestOut      : Sample(8),
      trdRegTsTimeIn  : Sample(8),
      trdRegTsTimeOut : Sample(8),
      responseIn      : Sample(8),
      sendingTime     : Sample(8),
      msgSeqNum       : Sample(4),
      lastFragment    : Sample(1),
      pad3            : Sample(3) ]

EncodeNrResponseHeaderMeComp11(message) ==
    message.requestTime
        \o message.requestOut
        \o message.trdRegTsTimeIn
        \o message.trdRegTsTimeOut
        \o message.responseIn
        \o message.sendingTime
        \o message.msgSeqNum
        \o message.lastFragment
        \o message.pad3

DecodeNrResponseHeaderMeComp11(bytes) ==
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

ZeroNrResponseHeaderMeComp11 ==
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
CheckedNrResponseHeaderMeComp11 ==
    { ZeroNrResponseHeaderMeComp11 }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.requestTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.requestOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.trdRegTsTimeIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.trdRegTsTimeOut = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.responseIn = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.lastFragment = one] : one \in Sample(1) }
        \cup { [ZeroNrResponseHeaderMeComp11 EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Reject                                                                  *)
(***************************************************************************)

Reject ==
    [ pad2                   : Sample(2),
      nrResponseHeaderMeComp : NrResponseHeaderMeComp11,
      sessionRejectReason    : Sample(4),
      sessionStatus          : Sample(1),
      pad1                   : Sample(1),
      varText                : SampleBytes,
      alignmentPadding       : SampleBytes ]

EncodeReject(message) ==
    message.pad2
        \o EncodeNrResponseHeaderMeComp11(message.nrResponseHeaderMeComp)
        \o message.sessionRejectReason
        \o EncodeUIntLE(Len(message.varText), 2)
        \o message.sessionStatus
        \o message.pad1
        \o message.varText
        \o message.alignmentPadding

DecodeReject(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrResponseHeaderMeComp == DecodeNrResponseHeaderMeComp11(pad2.rest) IN IF ~nrResponseHeaderMeComp.ok THEN Fail ELSE
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
      nrResponseHeaderMeComp |-> ZeroNrResponseHeaderMeComp11,
      sessionRejectReason    |-> [i \in 1 .. 4 |-> 0],
      sessionStatus          |-> [i \in 1 .. 1 |-> 0],
      pad1                   |-> [i \in 1 .. 1 |-> 0],
      varText                |-> << >>,
      alignmentPadding       |-> << >> ]

(* Reject at zero, then each field in turn at the values it is checked at *)
CheckedReject ==
    { ZeroReject }
        \cup { [ZeroReject EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroReject EXCEPT !.nrResponseHeaderMeComp = one] : one \in CheckedNrResponseHeaderMeComp11 }
        \cup { [ZeroReject EXCEPT !.sessionRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroReject EXCEPT !.sessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroReject EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroReject EXCEPT !.varText = one] : one \in SampleBytes }
        \cup { [ZeroReject EXCEPT !.alignmentPadding = one] : one \in SampleBytes }

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
(* Retransmit Me Message Response: 66 bytes                                *)
(***************************************************************************)

RetransmitMeMessageResponse ==
    [ pad2                  : Sample(2),
      responseHeaderComp    : ResponseHeaderComp7,
      applTotalMessageCount : Sample(2),
      applEndMsgId          : Sample(16),
      refApplLastMsgId      : Sample(16),
      pad6                  : Sample(6) ]

EncodeRetransmitMeMessageResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp7(message.responseHeaderComp)
        \o message.applTotalMessageCount
        \o message.applEndMsgId
        \o message.refApplLastMsgId
        \o message.pad6

DecodeRetransmitMeMessageResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp7(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
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
      responseHeaderComp    |-> ZeroResponseHeaderComp7,
      applTotalMessageCount |-> [i \in 1 .. 2 |-> 0],
      applEndMsgId          |-> [i \in 1 .. 16 |-> 0],
      refApplLastMsgId      |-> [i \in 1 .. 16 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Retransmit Me Message Response at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitMeMessageResponse ==
    { ZeroRetransmitMeMessageResponse }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp7 }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.applTotalMessageCount = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.applEndMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.refApplLastMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageResponse EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Retransmit Response: 50 bytes                                           *)
(***************************************************************************)

RetransmitResponse ==
    [ pad2                  : Sample(2),
      responseHeaderComp    : ResponseHeaderComp8,
      applEndSeqNum         : Sample(8),
      refApplLastSeqNum     : Sample(8),
      applTotalMessageCount : Sample(2),
      pad6                  : Sample(6) ]

EncodeRetransmitResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp8(message.responseHeaderComp)
        \o message.applEndSeqNum
        \o message.refApplLastSeqNum
        \o message.applTotalMessageCount
        \o message.pad6

DecodeRetransmitResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp8(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
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
      responseHeaderComp    |-> ZeroResponseHeaderComp8,
      applEndSeqNum         |-> [i \in 1 .. 8 |-> 0],
      refApplLastSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applTotalMessageCount |-> [i \in 1 .. 2 |-> 0],
      pad6                  |-> [i \in 1 .. 6 |-> 0] ]

(* Retransmit Response at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitResponse ==
    { ZeroRetransmitResponse }
        \cup { [ZeroRetransmitResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp8 }
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
(* Service Availability Broadcast: 42 bytes                                *)
(***************************************************************************)

ServiceAvailabilityBroadcast ==
    [ pad2                    : Sample(2),
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
    message.pad2
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
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET nrbcHeaderComp == DecodeNrbcHeaderComp(pad2.rest) IN IF ~nrbcHeaderComp.ok THEN Fail ELSE
    LET matchingEngineTradeDate == ReadBytes(nrbcHeaderComp.rest, 4) IN IF ~matchingEngineTradeDate.ok THEN Fail ELSE
    LET tradeManagerTradeDate == ReadBytes(matchingEngineTradeDate.rest, 4) IN IF ~tradeManagerTradeDate.ok THEN Fail ELSE
    LET applSeqTradeDate == ReadBytes(tradeManagerTradeDate.rest, 4) IN IF ~applSeqTradeDate.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applSeqTradeDate.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET matchingEngineStatus == ReadBytes(partitionId.rest, 1) IN IF ~matchingEngineStatus.ok THEN Fail ELSE
    LET tradeManagerStatus == ReadBytes(matchingEngineStatus.rest, 1) IN IF ~tradeManagerStatus.ok THEN Fail ELSE
    LET applSeqStatus == ReadBytes(tradeManagerStatus.rest, 1) IN IF ~applSeqStatus.ok THEN Fail ELSE
    LET pad7 == ReadBytes(applSeqStatus.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2                    |-> pad2.value,
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
    [ pad2                    |-> [i \in 1 .. 2 |-> 0],
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
        \cup { [ZeroServiceAvailabilityBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
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
(* Subscribe Response: 34 bytes                                            *)
(***************************************************************************)

SubscribeResponse ==
    [ pad2               : Sample(2),
      responseHeaderComp : ResponseHeaderComp9,
      applSubId          : Sample(4),
      pad4               : Sample(4) ]

EncodeSubscribeResponse(message) ==
    message.pad2
        \o EncodeResponseHeaderComp9(message.responseHeaderComp)
        \o message.applSubId
        \o message.pad4

DecodeSubscribeResponse(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET responseHeaderComp == DecodeResponseHeaderComp9(pad2.rest) IN IF ~responseHeaderComp.ok THEN Fail ELSE
    LET applSubId == ReadBytes(responseHeaderComp.rest, 4) IN IF ~applSubId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(applSubId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ pad2               |-> pad2.value,
         responseHeaderComp |-> responseHeaderComp.value,
         applSubId          |-> applSubId.value,
         pad4               |-> pad4.value ], pad4.rest)

ZeroSubscribeResponse ==
    [ pad2               |-> [i \in 1 .. 2 |-> 0],
      responseHeaderComp |-> ZeroResponseHeaderComp9,
      applSubId          |-> [i \in 1 .. 4 |-> 0],
      pad4               |-> [i \in 1 .. 4 |-> 0] ]

(* Subscribe Response at zero, then each field in turn at the values it is checked at *)
CheckedSubscribeResponse ==
    { ZeroSubscribeResponse }
        \cup { [ZeroSubscribeResponse EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSubscribeResponse EXCEPT !.responseHeaderComp = one] : one \in CheckedResponseHeaderComp9 }
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
    [ pad2          : Sample(2),
      rbcHeaderComp : RbcHeaderComp5,
      tradSesEvent  : Sample(1),
      pad7          : Sample(7) ]

EncodeTmTradingSessionStatusBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp5(message.rbcHeaderComp)
        \o message.tradSesEvent
        \o message.pad7

DecodeTmTradingSessionStatusBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp5(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET tradSesEvent == ReadBytes(rbcHeaderComp.rest, 1) IN IF ~tradSesEvent.ok THEN Fail ELSE
    LET pad7 == ReadBytes(tradSesEvent.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ pad2          |-> pad2.value,
         rbcHeaderComp |-> rbcHeaderComp.value,
         tradSesEvent  |-> tradSesEvent.value,
         pad7          |-> pad7.value ], pad7.rest)

ZeroTmTradingSessionStatusBroadcast ==
    [ pad2          |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp |-> ZeroRbcHeaderComp5,
      tradSesEvent  |-> [i \in 1 .. 1 |-> 0],
      pad7          |-> [i \in 1 .. 7 |-> 0] ]

(* Tm Trading Session Status Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTmTradingSessionStatusBroadcast ==
    { ZeroTmTradingSessionStatusBroadcast }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTmTradingSessionStatusBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp5 }
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
(* Trade Broadcast: 354 bytes                                              *)
(***************************************************************************)

TradeBroadcast ==
    [ pad2                              : Sample(2),
      rbcHeaderComp                     : RbcHeaderComp6,
      securityId                        : Sample(8),
      price                             : Sample(8),
      lastPx                            : Sample(8),
      settlCurrAmt                      : Sample(8),
      settlCurrFxRate                   : Sample(8),
      transactTime                      : Sample(8),
      orderId                           : Sample(8),
      clOrdId                           : Sample(8),
      tradeId                           : Sample(4),
      origTradeId                       : Sample(4),
      rootPartyIdExecutingUnit          : Sample(4),
      rootPartyIdSessionId              : Sample(4),
      rootPartyIdExecutingTrader        : Sample(4),
      rootPartyIdSettlementUnit         : Sample(4),
      rootPartyIdClearingUnit           : Sample(4),
      rootPartyIdContraUnit             : Sample(4),
      rootPartyIdContraSettlementUnit   : Sample(4),
      orderIdSfx                        : Sample(4),
      cumQty                            : Sample(4),
      leavesQty                         : Sample(4),
      marketSegmentId                   : Sample(4),
      lastQty                           : Sample(4),
      sideTradeId                       : Sample(4),
      sideTradeReportId                 : Sample(4),
      tradeNumber                       : Sample(4),
      matchDate                         : Sample(4),
      settlDate                         : Sample(4),
      trdMatchId                        : Sample(4),
      lastMkt                           : Sample(2),
      tradeReportType                   : Sample(1),
      transferReason                    : Sample(1),
      matchType                         : Sample(1),
      matchSubType                      : Sample(1),
      side                              : Sample(1),
      sideLiquidityInd                  : Sample(1),
      deliveryType                      : Sample(1),
      tradingCapacity                   : Sample(1),
      account                           : Sample(2),
      settlCurrency                     : Sample(3),
      currency                          : Sample(3),
      freeText1                         : Sample(12),
      freeText2                         : Sample(12),
      freeText4                         : Sample(16),
      orderCategory                     : Sample(1),
      ordType                           : Sample(1),
      rootPartyExecutingFirm            : Sample(5),
      rootPartyExecutingTrader          : Sample(6),
      rootPartyClearingFirm             : Sample(5),
      rootPartyExecutingFirmKvNumber    : Sample(4),
      rootPartySettlementAccount        : Sample(35),
      rootPartySettlementLocation       : Sample(3),
      rootPartySettlementFirm           : Sample(5),
      rootPartyContraFirm               : Sample(5),
      rootPartyContraSettlementFirm     : Sample(5),
      rootPartyContraFirmKvNumber       : Sample(4),
      rootPartyContraSettlementAccount  : Sample(35),
      rootPartyContraSettlementLocation : Sample(3),
      pad1                              : Sample(1) ]

EncodeTradeBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderComp6(message.rbcHeaderComp)
        \o message.securityId
        \o message.price
        \o message.lastPx
        \o message.settlCurrAmt
        \o message.settlCurrFxRate
        \o message.transactTime
        \o message.orderId
        \o message.clOrdId
        \o message.tradeId
        \o message.origTradeId
        \o message.rootPartyIdExecutingUnit
        \o message.rootPartyIdSessionId
        \o message.rootPartyIdExecutingTrader
        \o message.rootPartyIdSettlementUnit
        \o message.rootPartyIdClearingUnit
        \o message.rootPartyIdContraUnit
        \o message.rootPartyIdContraSettlementUnit
        \o message.orderIdSfx
        \o message.cumQty
        \o message.leavesQty
        \o message.marketSegmentId
        \o message.lastQty
        \o message.sideTradeId
        \o message.sideTradeReportId
        \o message.tradeNumber
        \o message.matchDate
        \o message.settlDate
        \o message.trdMatchId
        \o message.lastMkt
        \o message.tradeReportType
        \o message.transferReason
        \o message.matchType
        \o message.matchSubType
        \o message.side
        \o message.sideLiquidityInd
        \o message.deliveryType
        \o message.tradingCapacity
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
        \o message.pad1

DecodeTradeBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderComp == DecodeRbcHeaderComp6(pad2.rest) IN IF ~rbcHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(rbcHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET lastPx == ReadBytes(price.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET settlCurrAmt == ReadBytes(lastPx.rest, 8) IN IF ~settlCurrAmt.ok THEN Fail ELSE
    LET settlCurrFxRate == ReadBytes(settlCurrAmt.rest, 8) IN IF ~settlCurrFxRate.ok THEN Fail ELSE
    LET transactTime == ReadBytes(settlCurrFxRate.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactTime.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(clOrdId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET origTradeId == ReadBytes(tradeId.rest, 4) IN IF ~origTradeId.ok THEN Fail ELSE
    LET rootPartyIdExecutingUnit == ReadBytes(origTradeId.rest, 4) IN IF ~rootPartyIdExecutingUnit.ok THEN Fail ELSE
    LET rootPartyIdSessionId == ReadBytes(rootPartyIdExecutingUnit.rest, 4) IN IF ~rootPartyIdSessionId.ok THEN Fail ELSE
    LET rootPartyIdExecutingTrader == ReadBytes(rootPartyIdSessionId.rest, 4) IN IF ~rootPartyIdExecutingTrader.ok THEN Fail ELSE
    LET rootPartyIdSettlementUnit == ReadBytes(rootPartyIdExecutingTrader.rest, 4) IN IF ~rootPartyIdSettlementUnit.ok THEN Fail ELSE
    LET rootPartyIdClearingUnit == ReadBytes(rootPartyIdSettlementUnit.rest, 4) IN IF ~rootPartyIdClearingUnit.ok THEN Fail ELSE
    LET rootPartyIdContraUnit == ReadBytes(rootPartyIdClearingUnit.rest, 4) IN IF ~rootPartyIdContraUnit.ok THEN Fail ELSE
    LET rootPartyIdContraSettlementUnit == ReadBytes(rootPartyIdContraUnit.rest, 4) IN IF ~rootPartyIdContraSettlementUnit.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(rootPartyIdContraSettlementUnit.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET cumQty == ReadBytes(orderIdSfx.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(cumQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(leavesQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET sideTradeId == ReadBytes(lastQty.rest, 4) IN IF ~sideTradeId.ok THEN Fail ELSE
    LET sideTradeReportId == ReadBytes(sideTradeId.rest, 4) IN IF ~sideTradeReportId.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(sideTradeReportId.rest, 4) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET matchDate == ReadBytes(tradeNumber.rest, 4) IN IF ~matchDate.ok THEN Fail ELSE
    LET settlDate == ReadBytes(matchDate.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(settlDate.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET lastMkt == ReadBytes(trdMatchId.rest, 2) IN IF ~lastMkt.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(lastMkt.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET transferReason == ReadBytes(tradeReportType.rest, 1) IN IF ~transferReason.ok THEN Fail ELSE
    LET matchType == ReadBytes(transferReason.rest, 1) IN IF ~matchType.ok THEN Fail ELSE
    LET matchSubType == ReadBytes(matchType.rest, 1) IN IF ~matchSubType.ok THEN Fail ELSE
    LET side == ReadBytes(matchSubType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sideLiquidityInd == ReadBytes(side.rest, 1) IN IF ~sideLiquidityInd.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(sideLiquidityInd.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(deliveryType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET account == ReadBytes(tradingCapacity.rest, 2) IN IF ~account.ok THEN Fail ELSE
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
    LET pad1 == ReadBytes(rootPartyContraSettlementLocation.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ pad2                              |-> pad2.value,
         rbcHeaderComp                     |-> rbcHeaderComp.value,
         securityId                        |-> securityId.value,
         price                             |-> price.value,
         lastPx                            |-> lastPx.value,
         settlCurrAmt                      |-> settlCurrAmt.value,
         settlCurrFxRate                   |-> settlCurrFxRate.value,
         transactTime                      |-> transactTime.value,
         orderId                           |-> orderId.value,
         clOrdId                           |-> clOrdId.value,
         tradeId                           |-> tradeId.value,
         origTradeId                       |-> origTradeId.value,
         rootPartyIdExecutingUnit          |-> rootPartyIdExecutingUnit.value,
         rootPartyIdSessionId              |-> rootPartyIdSessionId.value,
         rootPartyIdExecutingTrader        |-> rootPartyIdExecutingTrader.value,
         rootPartyIdSettlementUnit         |-> rootPartyIdSettlementUnit.value,
         rootPartyIdClearingUnit           |-> rootPartyIdClearingUnit.value,
         rootPartyIdContraUnit             |-> rootPartyIdContraUnit.value,
         rootPartyIdContraSettlementUnit   |-> rootPartyIdContraSettlementUnit.value,
         orderIdSfx                        |-> orderIdSfx.value,
         cumQty                            |-> cumQty.value,
         leavesQty                         |-> leavesQty.value,
         marketSegmentId                   |-> marketSegmentId.value,
         lastQty                           |-> lastQty.value,
         sideTradeId                       |-> sideTradeId.value,
         sideTradeReportId                 |-> sideTradeReportId.value,
         tradeNumber                       |-> tradeNumber.value,
         matchDate                         |-> matchDate.value,
         settlDate                         |-> settlDate.value,
         trdMatchId                        |-> trdMatchId.value,
         lastMkt                           |-> lastMkt.value,
         tradeReportType                   |-> tradeReportType.value,
         transferReason                    |-> transferReason.value,
         matchType                         |-> matchType.value,
         matchSubType                      |-> matchSubType.value,
         side                              |-> side.value,
         sideLiquidityInd                  |-> sideLiquidityInd.value,
         deliveryType                      |-> deliveryType.value,
         tradingCapacity                   |-> tradingCapacity.value,
         account                           |-> account.value,
         settlCurrency                     |-> settlCurrency.value,
         currency                          |-> currency.value,
         freeText1                         |-> freeText1.value,
         freeText2                         |-> freeText2.value,
         freeText4                         |-> freeText4.value,
         orderCategory                     |-> orderCategory.value,
         ordType                           |-> ordType.value,
         rootPartyExecutingFirm            |-> rootPartyExecutingFirm.value,
         rootPartyExecutingTrader          |-> rootPartyExecutingTrader.value,
         rootPartyClearingFirm             |-> rootPartyClearingFirm.value,
         rootPartyExecutingFirmKvNumber    |-> rootPartyExecutingFirmKvNumber.value,
         rootPartySettlementAccount        |-> rootPartySettlementAccount.value,
         rootPartySettlementLocation       |-> rootPartySettlementLocation.value,
         rootPartySettlementFirm           |-> rootPartySettlementFirm.value,
         rootPartyContraFirm               |-> rootPartyContraFirm.value,
         rootPartyContraSettlementFirm     |-> rootPartyContraSettlementFirm.value,
         rootPartyContraFirmKvNumber       |-> rootPartyContraFirmKvNumber.value,
         rootPartyContraSettlementAccount  |-> rootPartyContraSettlementAccount.value,
         rootPartyContraSettlementLocation |-> rootPartyContraSettlementLocation.value,
         pad1                              |-> pad1.value ], pad1.rest)

ZeroTradeBroadcast ==
    [ pad2                              |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderComp                     |-> ZeroRbcHeaderComp6,
      securityId                        |-> [i \in 1 .. 8 |-> 0],
      price                             |-> [i \in 1 .. 8 |-> 0],
      lastPx                            |-> [i \in 1 .. 8 |-> 0],
      settlCurrAmt                      |-> [i \in 1 .. 8 |-> 0],
      settlCurrFxRate                   |-> [i \in 1 .. 8 |-> 0],
      transactTime                      |-> [i \in 1 .. 8 |-> 0],
      orderId                           |-> [i \in 1 .. 8 |-> 0],
      clOrdId                           |-> [i \in 1 .. 8 |-> 0],
      tradeId                           |-> [i \in 1 .. 4 |-> 0],
      origTradeId                       |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdExecutingUnit          |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdSessionId              |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdExecutingTrader        |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdSettlementUnit         |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdClearingUnit           |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdContraUnit             |-> [i \in 1 .. 4 |-> 0],
      rootPartyIdContraSettlementUnit   |-> [i \in 1 .. 4 |-> 0],
      orderIdSfx                        |-> [i \in 1 .. 4 |-> 0],
      cumQty                            |-> [i \in 1 .. 4 |-> 0],
      leavesQty                         |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                   |-> [i \in 1 .. 4 |-> 0],
      lastQty                           |-> [i \in 1 .. 4 |-> 0],
      sideTradeId                       |-> [i \in 1 .. 4 |-> 0],
      sideTradeReportId                 |-> [i \in 1 .. 4 |-> 0],
      tradeNumber                       |-> [i \in 1 .. 4 |-> 0],
      matchDate                         |-> [i \in 1 .. 4 |-> 0],
      settlDate                         |-> [i \in 1 .. 4 |-> 0],
      trdMatchId                        |-> [i \in 1 .. 4 |-> 0],
      lastMkt                           |-> [i \in 1 .. 2 |-> 0],
      tradeReportType                   |-> [i \in 1 .. 1 |-> 0],
      transferReason                    |-> [i \in 1 .. 1 |-> 0],
      matchType                         |-> [i \in 1 .. 1 |-> 0],
      matchSubType                      |-> [i \in 1 .. 1 |-> 0],
      side                              |-> [i \in 1 .. 1 |-> 0],
      sideLiquidityInd                  |-> [i \in 1 .. 1 |-> 0],
      deliveryType                      |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                   |-> [i \in 1 .. 1 |-> 0],
      account                           |-> [i \in 1 .. 2 |-> 0],
      settlCurrency                     |-> [i \in 1 .. 3 |-> 0],
      currency                          |-> [i \in 1 .. 3 |-> 0],
      freeText1                         |-> [i \in 1 .. 12 |-> 0],
      freeText2                         |-> [i \in 1 .. 12 |-> 0],
      freeText4                         |-> [i \in 1 .. 16 |-> 0],
      orderCategory                     |-> [i \in 1 .. 1 |-> 0],
      ordType                           |-> [i \in 1 .. 1 |-> 0],
      rootPartyExecutingFirm            |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingTrader          |-> [i \in 1 .. 6 |-> 0],
      rootPartyClearingFirm             |-> [i \in 1 .. 5 |-> 0],
      rootPartyExecutingFirmKvNumber    |-> [i \in 1 .. 4 |-> 0],
      rootPartySettlementAccount        |-> [i \in 1 .. 35 |-> 0],
      rootPartySettlementLocation       |-> [i \in 1 .. 3 |-> 0],
      rootPartySettlementFirm           |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraFirm               |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraSettlementFirm     |-> [i \in 1 .. 5 |-> 0],
      rootPartyContraFirmKvNumber       |-> [i \in 1 .. 4 |-> 0],
      rootPartyContraSettlementAccount  |-> [i \in 1 .. 35 |-> 0],
      rootPartyContraSettlementLocation |-> [i \in 1 .. 3 |-> 0],
      pad1                              |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTradeBroadcast ==
    { ZeroTradeBroadcast }
        \cup { [ZeroTradeBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rbcHeaderComp = one] : one \in CheckedRbcHeaderComp6 }
        \cup { [ZeroTradeBroadcast EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.settlCurrAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.settlCurrFxRate = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.origTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdExecutingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdSettlementUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdClearingUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdContraUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.rootPartyIdContraSettlementUnit = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideTradeReportId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradeNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.matchDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBroadcast EXCEPT !.lastMkt = one] : one \in Sample(2) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.transferReason = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.matchType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.matchSubType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.sideLiquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroTradeBroadcast EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
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
        \cup { [ZeroTradeBroadcast EXCEPT !.pad1 = one] : one \in Sample(1) }

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
(* Trading Session Status Broadcast: 90 bytes                              *)
(***************************************************************************)

TradingSessionStatusBroadcast ==
    [ pad2             : Sample(2),
      rbcHeaderMeComp  : RbcHeaderMeComp12,
      marketSegmentId  : Sample(4),
      tradeDate        : Sample(4),
      tradSesEvent     : Sample(1),
      refApplLastMsgId : Sample(16),
      pad7             : Sample(7) ]

EncodeTradingSessionStatusBroadcast(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp12(message.rbcHeaderMeComp)
        \o message.marketSegmentId
        \o message.tradeDate
        \o message.tradSesEvent
        \o message.refApplLastMsgId
        \o message.pad7

DecodeTradingSessionStatusBroadcast(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp12(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
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
      rbcHeaderMeComp  |-> ZeroRbcHeaderMeComp12,
      marketSegmentId  |-> [i \in 1 .. 4 |-> 0],
      tradeDate        |-> [i \in 1 .. 4 |-> 0],
      tradSesEvent     |-> [i \in 1 .. 1 |-> 0],
      refApplLastMsgId |-> [i \in 1 .. 16 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Trading Session Status Broadcast at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusBroadcast ==
    { ZeroTradingSessionStatusBroadcast }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp12 }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.tradSesEvent = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.refApplLastMsgId = one] : one \in Sample(16) }
        \cup { [ZeroTradingSessionStatusBroadcast EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Trailing Stop Update Notification: 146 bytes                            *)
(***************************************************************************)

TrailingStopUpdateNotification ==
    [ pad2                  : Sample(2),
      rbcHeaderMeComp       : RbcHeaderMeComp13,
      orderId               : Sample(8),
      clOrdId               : Sample(8),
      origClOrdId           : Sample(8),
      securityId            : Sample(8),
      execId                : Sample(8),
      stopPx                : Sample(8),
      orderIdSfx            : Sample(4),
      marketSegmentId       : Sample(4),
      orderQty              : Sample(4),
      execRestatementReason : Sample(2),
      ordStatus             : Sample(1),
      execType              : Sample(1),
      side                  : Sample(1),
      fixClOrdId            : Sample(20),
      pad3                  : Sample(3) ]

EncodeTrailingStopUpdateNotification(message) ==
    message.pad2
        \o EncodeRbcHeaderMeComp13(message.rbcHeaderMeComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.execId
        \o message.stopPx
        \o message.orderIdSfx
        \o message.marketSegmentId
        \o message.orderQty
        \o message.execRestatementReason
        \o message.ordStatus
        \o message.execType
        \o message.side
        \o message.fixClOrdId
        \o message.pad3

DecodeTrailingStopUpdateNotification(bytes) ==
    LET pad2 == ReadBytes(bytes, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET rbcHeaderMeComp == DecodeRbcHeaderMeComp13(pad2.rest) IN IF ~rbcHeaderMeComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(rbcHeaderMeComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET execId == ReadBytes(securityId.rest, 8) IN IF ~execId.ok THEN Fail ELSE
    LET stopPx == ReadBytes(execId.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET orderIdSfx == ReadBytes(stopPx.rest, 4) IN IF ~orderIdSfx.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderIdSfx.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET execRestatementReason == ReadBytes(orderQty.rest, 2) IN IF ~execRestatementReason.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(execRestatementReason.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET execType == ReadBytes(ordStatus.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET side == ReadBytes(execType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(side.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET pad3 == ReadBytes(fixClOrdId.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ pad2                  |-> pad2.value,
         rbcHeaderMeComp       |-> rbcHeaderMeComp.value,
         orderId               |-> orderId.value,
         clOrdId               |-> clOrdId.value,
         origClOrdId           |-> origClOrdId.value,
         securityId            |-> securityId.value,
         execId                |-> execId.value,
         stopPx                |-> stopPx.value,
         orderIdSfx            |-> orderIdSfx.value,
         marketSegmentId       |-> marketSegmentId.value,
         orderQty              |-> orderQty.value,
         execRestatementReason |-> execRestatementReason.value,
         ordStatus             |-> ordStatus.value,
         execType              |-> execType.value,
         side                  |-> side.value,
         fixClOrdId            |-> fixClOrdId.value,
         pad3                  |-> pad3.value ], pad3.rest)

ZeroTrailingStopUpdateNotification ==
    [ pad2                  |-> [i \in 1 .. 2 |-> 0],
      rbcHeaderMeComp       |-> ZeroRbcHeaderMeComp13,
      orderId               |-> [i \in 1 .. 8 |-> 0],
      clOrdId               |-> [i \in 1 .. 8 |-> 0],
      origClOrdId           |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 8 |-> 0],
      execId                |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      orderIdSfx            |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      execRestatementReason |-> [i \in 1 .. 2 |-> 0],
      ordStatus             |-> [i \in 1 .. 1 |-> 0],
      execType              |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      fixClOrdId            |-> [i \in 1 .. 20 |-> 0],
      pad3                  |-> [i \in 1 .. 3 |-> 0] ]

(* Trailing Stop Update Notification at zero, then each field in turn at the values it is checked at *)
CheckedTrailingStopUpdateNotification ==
    { ZeroTrailingStopUpdateNotification }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.rbcHeaderMeComp = one] : one \in CheckedRbcHeaderMeComp13 }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.execId = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.orderIdSfx = one] : one \in Sample(4) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.execRestatementReason = one] : one \in Sample(2) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroTrailingStopUpdateNotification EXCEPT !.pad3 = one] : one \in Sample(3) }

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
GatewayResponseCode == 10021  \* 0x2725
HeartbeatNotificationCode == 10023  \* 0x2727
InquireEnrichmentRuleIdListResponseCode == 10041  \* 0x2739
InquireSessionListResponseCode == 10036  \* 0x2734
InquireUserResponseCode == 10039  \* 0x2737
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
RfqResponseCode == 10402  \* 0x28a2
RejectCode == 10010  \* 0x271a
RetransmitMeMessageResponseCode == 10027  \* 0x272b
RetransmitResponseCode == 10009  \* 0x2719
ServiceAvailabilityBroadcastCode == 10030  \* 0x272e
SubscribeResponseCode == 10005  \* 0x2715
TmTradingSessionStatusBroadcastCode == 10501  \* 0x2905
ThrottleUpdateNotificationCode == 10028  \* 0x272c
TradeBroadcastCode == 10500  \* 0x2904
TradingSessionStatusBroadcastCode == 10307  \* 0x2843
TrailingStopUpdateNotificationCode == 10127  \* 0x278f
UnsubscribeResponseCode == 10007  \* 0x2717
UserLoginResponseCode == 10019  \* 0x2723
UserLogoutResponseCode == 10024  \* 0x2728

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
        \cup [ tag : {GatewayResponseCode}, body : GatewayResponse ]
        \cup [ tag : {HeartbeatNotificationCode}, body : HeartbeatNotification ]
        \cup [ tag : {InquireEnrichmentRuleIdListResponseCode}, body : InquireEnrichmentRuleIdListResponse ]
        \cup [ tag : {InquireSessionListResponseCode}, body : InquireSessionListResponse ]
        \cup [ tag : {InquireUserResponseCode}, body : InquireUserResponse ]
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
        \cup [ tag : {RfqResponseCode}, body : RfqResponse ]
        \cup [ tag : {RejectCode}, body : Reject ]
        \cup [ tag : {RetransmitMeMessageResponseCode}, body : RetransmitMeMessageResponse ]
        \cup [ tag : {RetransmitResponseCode}, body : RetransmitResponse ]
        \cup [ tag : {ServiceAvailabilityBroadcastCode}, body : ServiceAvailabilityBroadcast ]
        \cup [ tag : {SubscribeResponseCode}, body : SubscribeResponse ]
        \cup [ tag : {TmTradingSessionStatusBroadcastCode}, body : TmTradingSessionStatusBroadcast ]
        \cup [ tag : {ThrottleUpdateNotificationCode}, body : ThrottleUpdateNotification ]
        \cup [ tag : {TradeBroadcastCode}, body : TradeBroadcast ]
        \cup [ tag : {TradingSessionStatusBroadcastCode}, body : TradingSessionStatusBroadcast ]
        \cup [ tag : {TrailingStopUpdateNotificationCode}, body : TrailingStopUpdateNotification ]
        \cup [ tag : {UnsubscribeResponseCode}, body : UnsubscribeResponse ]
        \cup [ tag : {UserLoginResponseCode}, body : UserLoginResponse ]
        \cup [ tag : {UserLogoutResponseCode}, body : UserLogoutResponse ]

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
      [] message.tag = GatewayResponseCode -> EncodeGatewayResponse(message.body)
      [] message.tag = HeartbeatNotificationCode -> EncodeHeartbeatNotification(message.body)
      [] message.tag = InquireEnrichmentRuleIdListResponseCode -> EncodeInquireEnrichmentRuleIdListResponse(message.body)
      [] message.tag = InquireSessionListResponseCode -> EncodeInquireSessionListResponse(message.body)
      [] message.tag = InquireUserResponseCode -> EncodeInquireUserResponse(message.body)
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
      [] message.tag = RfqResponseCode -> EncodeRfqResponse(message.body)
      [] message.tag = RejectCode -> EncodeReject(message.body)
      [] message.tag = RetransmitMeMessageResponseCode -> EncodeRetransmitMeMessageResponse(message.body)
      [] message.tag = RetransmitResponseCode -> EncodeRetransmitResponse(message.body)
      [] message.tag = ServiceAvailabilityBroadcastCode -> EncodeServiceAvailabilityBroadcast(message.body)
      [] message.tag = SubscribeResponseCode -> EncodeSubscribeResponse(message.body)
      [] message.tag = TmTradingSessionStatusBroadcastCode -> EncodeTmTradingSessionStatusBroadcast(message.body)
      [] message.tag = ThrottleUpdateNotificationCode -> EncodeThrottleUpdateNotification(message.body)
      [] message.tag = TradeBroadcastCode -> EncodeTradeBroadcast(message.body)
      [] message.tag = TradingSessionStatusBroadcastCode -> EncodeTradingSessionStatusBroadcast(message.body)
      [] message.tag = TrailingStopUpdateNotificationCode -> EncodeTrailingStopUpdateNotification(message.body)
      [] message.tag = UnsubscribeResponseCode -> EncodeUnsubscribeResponse(message.body)
      [] message.tag = UserLoginResponseCode -> EncodeUserLoginResponse(message.body)
      [] message.tag = UserLogoutResponseCode -> EncodeUserLogoutResponse(message.body)

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
              [] tag = GatewayResponseCode -> DecodeGatewayResponse(bytes)
              [] tag = HeartbeatNotificationCode -> DecodeHeartbeatNotification(bytes)
              [] tag = InquireEnrichmentRuleIdListResponseCode -> DecodeInquireEnrichmentRuleIdListResponse(bytes)
              [] tag = InquireSessionListResponseCode -> DecodeInquireSessionListResponse(bytes)
              [] tag = InquireUserResponseCode -> DecodeInquireUserResponse(bytes)
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
              [] tag = RfqResponseCode -> DecodeRfqResponse(bytes)
              [] tag = RejectCode -> DecodeReject(bytes)
              [] tag = RetransmitMeMessageResponseCode -> DecodeRetransmitMeMessageResponse(bytes)
              [] tag = RetransmitResponseCode -> DecodeRetransmitResponse(bytes)
              [] tag = ServiceAvailabilityBroadcastCode -> DecodeServiceAvailabilityBroadcast(bytes)
              [] tag = SubscribeResponseCode -> DecodeSubscribeResponse(bytes)
              [] tag = TmTradingSessionStatusBroadcastCode -> DecodeTmTradingSessionStatusBroadcast(bytes)
              [] tag = ThrottleUpdateNotificationCode -> DecodeThrottleUpdateNotification(bytes)
              [] tag = TradeBroadcastCode -> DecodeTradeBroadcast(bytes)
              [] tag = TradingSessionStatusBroadcastCode -> DecodeTradingSessionStatusBroadcast(bytes)
              [] tag = TrailingStopUpdateNotificationCode -> DecodeTrailingStopUpdateNotification(bytes)
              [] tag = UnsubscribeResponseCode -> DecodeUnsubscribeResponse(bytes)
              [] tag = UserLoginResponseCode -> DecodeUserLoginResponse(bytes)
              [] tag = UserLogoutResponseCode -> DecodeUserLogoutResponse(bytes)
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
        \cup { [tag |-> GatewayResponseCode, body |-> one] : one \in CheckedGatewayResponse }
        \cup { [tag |-> HeartbeatNotificationCode, body |-> one] : one \in CheckedHeartbeatNotification }
        \cup { [tag |-> InquireEnrichmentRuleIdListResponseCode, body |-> one] : one \in CheckedInquireEnrichmentRuleIdListResponse }
        \cup { [tag |-> InquireSessionListResponseCode, body |-> one] : one \in CheckedInquireSessionListResponse }
        \cup { [tag |-> InquireUserResponseCode, body |-> one] : one \in CheckedInquireUserResponse }
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
        \cup { [tag |-> RfqResponseCode, body |-> one] : one \in CheckedRfqResponse }
        \cup { [tag |-> RejectCode, body |-> one] : one \in CheckedReject }
        \cup { [tag |-> RetransmitMeMessageResponseCode, body |-> one] : one \in CheckedRetransmitMeMessageResponse }
        \cup { [tag |-> RetransmitResponseCode, body |-> one] : one \in CheckedRetransmitResponse }
        \cup { [tag |-> ServiceAvailabilityBroadcastCode, body |-> one] : one \in CheckedServiceAvailabilityBroadcast }
        \cup { [tag |-> SubscribeResponseCode, body |-> one] : one \in CheckedSubscribeResponse }
        \cup { [tag |-> TmTradingSessionStatusBroadcastCode, body |-> one] : one \in CheckedTmTradingSessionStatusBroadcast }
        \cup { [tag |-> ThrottleUpdateNotificationCode, body |-> one] : one \in CheckedThrottleUpdateNotification }
        \cup { [tag |-> TradeBroadcastCode, body |-> one] : one \in CheckedTradeBroadcast }
        \cup { [tag |-> TradingSessionStatusBroadcastCode, body |-> one] : one \in CheckedTradingSessionStatusBroadcast }
        \cup { [tag |-> TrailingStopUpdateNotificationCode, body |-> one] : one \in CheckedTrailingStopUpdateNotification }
        \cup { [tag |-> UnsubscribeResponseCode, body |-> one] : one \in CheckedUnsubscribeResponse }
        \cup { [tag |-> UserLoginResponseCode, body |-> one] : one \in CheckedUserLoginResponse }
        \cup { [tag |-> UserLogoutResponseCode, body |-> one] : one \in CheckedUserLogoutResponse }

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
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> GatewayResponseCode, body |-> ZeroGatewayResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> HeartbeatNotificationCode, body |-> ZeroHeartbeatNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> InquireEnrichmentRuleIdListResponseCode, body |-> ZeroInquireEnrichmentRuleIdListResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> InquireSessionListResponseCode, body |-> ZeroInquireSessionListResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> InquireUserResponseCode, body |-> ZeroInquireUserResponse]],
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
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RfqResponseCode, body |-> ZeroRfqResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RejectCode, body |-> ZeroReject]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RetransmitMeMessageResponseCode, body |-> ZeroRetransmitMeMessageResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> RetransmitResponseCode, body |-> ZeroRetransmitResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ServiceAvailabilityBroadcastCode, body |-> ZeroServiceAvailabilityBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> SubscribeResponseCode, body |-> ZeroSubscribeResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TmTradingSessionStatusBroadcastCode, body |-> ZeroTmTradingSessionStatusBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> ThrottleUpdateNotificationCode, body |-> ZeroThrottleUpdateNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TradeBroadcastCode, body |-> ZeroTradeBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TradingSessionStatusBroadcastCode, body |-> ZeroTradingSessionStatusBroadcast]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> TrailingStopUpdateNotificationCode, body |-> ZeroTrailingStopUpdateNotification]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UnsubscribeResponseCode, body |-> ZeroUnsubscribeResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UserLoginResponseCode, body |-> ZeroUserLoginResponse]],
      [ZeroServerMessage EXCEPT !.serverPayload = [tag |-> UserLogoutResponseCode, body |-> ZeroUserLogoutResponse]] }

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
RoundTripResponseHeaderComp2 ==
    \A message \in CheckedResponseHeaderComp2 :
        LET read == DecodeResponseHeaderComp2(EncodeResponseHeaderComp2(message))
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
RoundTripResponseHeaderComp5 ==
    \A message \in CheckedResponseHeaderComp5 :
        LET read == DecodeResponseHeaderComp5(EncodeResponseHeaderComp5(message))
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
RoundTripResponseHeaderComp6 ==
    \A message \in CheckedResponseHeaderComp6 :
        LET read == DecodeResponseHeaderComp6(EncodeResponseHeaderComp6(message))
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
RoundTripNrResponseHeaderMeComp6 ==
    \A message \in CheckedNrResponseHeaderMeComp6 :
        LET read == DecodeNrResponseHeaderMeComp6(EncodeNrResponseHeaderMeComp6(message))
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
RoundTripNrResponseHeaderMeComp7 ==
    \A message \in CheckedNrResponseHeaderMeComp7 :
        LET read == DecodeNrResponseHeaderMeComp7(EncodeNrResponseHeaderMeComp7(message))
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
RoundTripRbcHeaderMeComp7 ==
    \A message \in CheckedRbcHeaderMeComp7 :
        LET read == DecodeRbcHeaderMeComp7(EncodeRbcHeaderMeComp7(message))
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
RoundTripRbcHeaderMeComp8 ==
    \A message \in CheckedRbcHeaderMeComp8 :
        LET read == DecodeRbcHeaderMeComp8(EncodeRbcHeaderMeComp8(message))
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
RoundTripRbcHeaderMeComp9 ==
    \A message \in CheckedRbcHeaderMeComp9 :
        LET read == DecodeRbcHeaderMeComp9(EncodeRbcHeaderMeComp9(message))
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
RoundTripNrResponseHeaderMeComp9 ==
    \A message \in CheckedNrResponseHeaderMeComp9 :
        LET read == DecodeNrResponseHeaderMeComp9(EncodeNrResponseHeaderMeComp9(message))
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
RoundTripRbcHeaderMeComp10 ==
    \A message \in CheckedRbcHeaderMeComp10 :
        LET read == DecodeRbcHeaderMeComp10(EncodeRbcHeaderMeComp10(message))
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
RoundTripRbcHeaderMeComp11 ==
    \A message \in CheckedRbcHeaderMeComp11 :
        LET read == DecodeRbcHeaderMeComp11(EncodeRbcHeaderMeComp11(message))
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

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp10 ==
    \A message \in CheckedNrResponseHeaderMeComp10 :
        LET read == DecodeNrResponseHeaderMeComp10(EncodeNrResponseHeaderMeComp10(message))
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

(* Every Nr Response Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripNrResponseHeaderMeComp11 ==
    \A message \in CheckedNrResponseHeaderMeComp11 :
        LET read == DecodeNrResponseHeaderMeComp11(EncodeNrResponseHeaderMeComp11(message))
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
RoundTripResponseHeaderComp7 ==
    \A message \in CheckedResponseHeaderComp7 :
        LET read == DecodeResponseHeaderComp7(EncodeResponseHeaderComp7(message))
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
RoundTripResponseHeaderComp8 ==
    \A message \in CheckedResponseHeaderComp8 :
        LET read == DecodeResponseHeaderComp8(EncodeResponseHeaderComp8(message))
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

(* Every Response Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseHeaderComp9 ==
    \A message \in CheckedResponseHeaderComp9 :
        LET read == DecodeResponseHeaderComp9(EncodeResponseHeaderComp9(message))
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

(* Every Rbc Header Me Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRbcHeaderMeComp12 ==
    \A message \in CheckedRbcHeaderMeComp12 :
        LET read == DecodeRbcHeaderMeComp12(EncodeRbcHeaderMeComp12(message))
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
RoundTripRbcHeaderMeComp13 ==
    \A message \in CheckedRbcHeaderMeComp13 :
        LET read == DecodeRbcHeaderMeComp13(EncodeRbcHeaderMeComp13(message))
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
