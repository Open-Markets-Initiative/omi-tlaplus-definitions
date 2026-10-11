-------------------- MODULE BseIndia_Eti_v1_6_14_Client --------------------
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
(* Note: Debt Inquiry Request fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete All Order Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete All Quote Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Delete Order Complex Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Delete Order Single Request fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Gateway Request fills what is left of the frame Body Len states,  *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Heartbeat fills what is left of the frame Body Len states, which  *)
(* is what it is read from.                                                *)
(*                                                                         *)
(* Note: Inquire Session List Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Logon Request fills what is left of the frame Body Len states,    *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Logout Request fills what is left of the frame Body Len states,   *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Mass Quote Request fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Modify Order Complex Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Modify Order Single Request fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Modify Order Single Short Request fills what is left of the frame *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Multi Leg Order Request fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: New Order Complex Request fills what is left of the frame Body    *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: New Order Single Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: New Order Single Short Request fills what is left of the frame    *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Retransmit Me Message Request fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Retransmit Request fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Session Password Change Request fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Session Registration Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Subscribe Request fills what is left of the frame Body Len        *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Unsubscribe Request fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Login Request fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Logout Request fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Password Change Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
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
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp ==
    { ZeroRequestHeaderComp }
        \cup { [ZeroRequestHeaderComp EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Debt Inquiry Request: 50 bytes                                          *)
(***************************************************************************)

DebtInquiryRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp,
      underlyingPx      : Sample(8),
      yield             : Sample(8),
      securityId        : Sample(8),
      orderQty          : Sample(4),
      pad4              : Sample(4) ]

EncodeDebtInquiryRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp(message.requestHeaderComp)
        \o message.underlyingPx
        \o message.yield
        \o message.securityId
        \o message.orderQty
        \o message.pad4

DecodeDebtInquiryRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET underlyingPx == ReadBytes(requestHeaderComp.rest, 8) IN IF ~underlyingPx.ok THEN Fail ELSE
    LET yield == ReadBytes(underlyingPx.rest, 8) IN IF ~yield.ok THEN Fail ELSE
    LET securityId == ReadBytes(yield.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET pad4 == ReadBytes(orderQty.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         underlyingPx      |-> underlyingPx.value,
         yield             |-> yield.value,
         securityId        |-> securityId.value,
         orderQty          |-> orderQty.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroDebtInquiryRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp,
      underlyingPx      |-> [i \in 1 .. 8 |-> 0],
      yield             |-> [i \in 1 .. 8 |-> 0],
      securityId        |-> [i \in 1 .. 8 |-> 0],
      orderQty          |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Debt Inquiry Request at zero, then each field in turn at the values it is checked at *)
CheckedDebtInquiryRequest ==
    { ZeroDebtInquiryRequest }
        \cup { [ZeroDebtInquiryRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDebtInquiryRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp }
        \cup { [ZeroDebtInquiryRequest EXCEPT !.underlyingPx = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryRequest EXCEPT !.yield = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDebtInquiryRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroDebtInquiryRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp2 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp2(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp2(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp2 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp2 ==
    { ZeroRequestHeaderComp2 }
        \cup { [ZeroRequestHeaderComp2 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp2 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete All Order Request: 58 bytes                                      *)
(***************************************************************************)

DeleteAllOrderRequest ==
    [ networkMsgId                 : Sample(8),
      pad2                         : Sample(2),
      requestHeaderComp            : RequestHeaderComp2,
      securityId                   : Sample(8),
      marketSegmentId              : Sample(4),
      regulatoryId                 : Sample(4),
      algoId                       : Sample(16),
      targetPartyIdSessionId       : Sample(4),
      targetPartyIdExecutingTrader : Sample(4) ]

EncodeDeleteAllOrderRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp2(message.requestHeaderComp)
        \o message.securityId
        \o message.marketSegmentId
        \o message.regulatoryId
        \o message.algoId
        \o message.targetPartyIdSessionId
        \o message.targetPartyIdExecutingTrader

DecodeDeleteAllOrderRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp2(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(securityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET regulatoryId == ReadBytes(marketSegmentId.rest, 4) IN IF ~regulatoryId.ok THEN Fail ELSE
    LET algoId == ReadBytes(regulatoryId.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(algoId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET targetPartyIdExecutingTrader == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    Ok([ networkMsgId                 |-> networkMsgId.value,
         pad2                         |-> pad2.value,
         requestHeaderComp            |-> requestHeaderComp.value,
         securityId                   |-> securityId.value,
         marketSegmentId              |-> marketSegmentId.value,
         regulatoryId                 |-> regulatoryId.value,
         algoId                       |-> algoId.value,
         targetPartyIdSessionId       |-> targetPartyIdSessionId.value,
         targetPartyIdExecutingTrader |-> targetPartyIdExecutingTrader.value ], targetPartyIdExecutingTrader.rest)

ZeroDeleteAllOrderRequest ==
    [ networkMsgId                 |-> [i \in 1 .. 8 |-> 0],
      pad2                         |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp            |-> ZeroRequestHeaderComp2,
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId              |-> [i \in 1 .. 4 |-> 0],
      regulatoryId                 |-> [i \in 1 .. 4 |-> 0],
      algoId                       |-> [i \in 1 .. 16 |-> 0],
      targetPartyIdSessionId       |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0] ]

(* Delete All Order Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderRequest ==
    { ZeroDeleteAllOrderRequest }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp2 }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.regulatoryId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp3 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp3(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp3(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp3 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp3 ==
    { ZeroRequestHeaderComp3 }
        \cup { [ZeroRequestHeaderComp3 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp3 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete All Quote Request: 50 bytes                                      *)
(***************************************************************************)

DeleteAllQuoteRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp3,
      marketSegmentId        : Sample(4),
      targetPartyIdSessionId : Sample(4),
      algoId                 : Sample(16),
      regulatoryId           : Sample(4),
      pad4                   : Sample(4) ]

EncodeDeleteAllQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp3(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.algoId
        \o message.regulatoryId
        \o message.pad4

DecodeDeleteAllQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp3(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET algoId == ReadBytes(targetPartyIdSessionId.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET regulatoryId == ReadBytes(algoId.rest, 4) IN IF ~regulatoryId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(regulatoryId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         marketSegmentId        |-> marketSegmentId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value,
         algoId                 |-> algoId.value,
         regulatoryId           |-> regulatoryId.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroDeleteAllQuoteRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp3,
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      regulatoryId           |-> [i \in 1 .. 4 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Delete All Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllQuoteRequest ==
    { ZeroDeleteAllQuoteRequest }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp3 }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.regulatoryId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp4 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp4(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp4(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp4 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp4 ==
    { ZeroRequestHeaderComp4 }
        \cup { [ZeroRequestHeaderComp4 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp4 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Order Complex Request: 90 bytes                                  *)
(***************************************************************************)

DeleteOrderComplexRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp4,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      filler1                : Sample(8),
      messageTag             : Sample(4),
      marketSegmentId        : Sample(4),
      targetPartyIdSessionId : Sample(4),
      regulatoryId           : Sample(4),
      algoId                 : Sample(16) ]

EncodeDeleteOrderComplexRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp4(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.filler1
        \o message.messageTag
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.regulatoryId
        \o message.algoId

DecodeDeleteOrderComplexRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp4(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET filler1 == ReadBytes(securityId.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET messageTag == ReadBytes(filler1.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(messageTag.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET regulatoryId == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~regulatoryId.ok THEN Fail ELSE
    LET algoId == ReadBytes(regulatoryId.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         filler1                |-> filler1.value,
         messageTag             |-> messageTag.value,
         marketSegmentId        |-> marketSegmentId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value,
         regulatoryId           |-> regulatoryId.value,
         algoId                 |-> algoId.value ], algoId.rest)

ZeroDeleteOrderComplexRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp4,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      filler1                |-> [i \in 1 .. 8 |-> 0],
      messageTag             |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0],
      regulatoryId           |-> [i \in 1 .. 4 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0] ]

(* Delete Order Complex Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderComplexRequest ==
    { ZeroDeleteOrderComplexRequest }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp4 }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.regulatoryId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.algoId = one] : one \in Sample(16) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp5 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp5(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp5(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp5 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp5 ==
    { ZeroRequestHeaderComp5 }
        \cup { [ZeroRequestHeaderComp5 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp5 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Delete Order Single Request: 90 bytes                                   *)
(***************************************************************************)

DeleteOrderSingleRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp5,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      filler1                : Sample(8),
      messageTag             : Sample(4),
      marketSegmentId        : Sample(4),
      simpleSecurityId       : Sample(4),
      targetPartyIdSessionId : Sample(4),
      regulatoryId           : Sample(4),
      algoId                 : Sample(16),
      pad4                   : Sample(4) ]

EncodeDeleteOrderSingleRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp5(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.filler1
        \o message.messageTag
        \o message.marketSegmentId
        \o message.simpleSecurityId
        \o message.targetPartyIdSessionId
        \o message.regulatoryId
        \o message.algoId
        \o message.pad4

DecodeDeleteOrderSingleRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp5(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET filler1 == ReadBytes(origClOrdId.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET messageTag == ReadBytes(filler1.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(messageTag.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(marketSegmentId.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(simpleSecurityId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET regulatoryId == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~regulatoryId.ok THEN Fail ELSE
    LET algoId == ReadBytes(regulatoryId.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(algoId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         filler1                |-> filler1.value,
         messageTag             |-> messageTag.value,
         marketSegmentId        |-> marketSegmentId.value,
         simpleSecurityId       |-> simpleSecurityId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value,
         regulatoryId           |-> regulatoryId.value,
         algoId                 |-> algoId.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroDeleteOrderSingleRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp5,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      filler1                |-> [i \in 1 .. 8 |-> 0],
      messageTag             |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId       |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0],
      regulatoryId           |-> [i \in 1 .. 4 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Delete Order Single Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderSingleRequest ==
    { ZeroDeleteOrderSingleRequest }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp5 }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.regulatoryId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp6 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp6(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp6(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp6 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp6 ==
    { ZeroRequestHeaderComp6 }
        \cup { [ZeroRequestHeaderComp6 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp6 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Gateway Request: 90 bytes                                               *)
(***************************************************************************)

GatewayRequest ==
    [ networkMsgId         : Sample(8),
      pad2                 : Sample(2),
      requestHeaderComp    : RequestHeaderComp6,
      partyIdSessionId     : Sample(4),
      defaultCstmApplVerId : Sample(30),
      password             : Sample(32),
      pad6                 : Sample(6) ]

EncodeGatewayRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp6(message.requestHeaderComp)
        \o message.partyIdSessionId
        \o message.defaultCstmApplVerId
        \o message.password
        \o message.pad6

DecodeGatewayRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp6(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET defaultCstmApplVerId == ReadBytes(partyIdSessionId.rest, 30) IN IF ~defaultCstmApplVerId.ok THEN Fail ELSE
    LET password == ReadBytes(defaultCstmApplVerId.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET pad6 == ReadBytes(password.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId         |-> networkMsgId.value,
         pad2                 |-> pad2.value,
         requestHeaderComp    |-> requestHeaderComp.value,
         partyIdSessionId     |-> partyIdSessionId.value,
         defaultCstmApplVerId |-> defaultCstmApplVerId.value,
         password             |-> password.value,
         pad6                 |-> pad6.value ], pad6.rest)

ZeroGatewayRequest ==
    [ networkMsgId         |-> [i \in 1 .. 8 |-> 0],
      pad2                 |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp    |-> ZeroRequestHeaderComp6,
      partyIdSessionId     |-> [i \in 1 .. 4 |-> 0],
      defaultCstmApplVerId |-> [i \in 1 .. 30 |-> 0],
      password             |-> [i \in 1 .. 32 |-> 0],
      pad6                 |-> [i \in 1 .. 6 |-> 0] ]

(* Gateway Request at zero, then each field in turn at the values it is checked at *)
CheckedGatewayRequest ==
    { ZeroGatewayRequest }
        \cup { [ZeroGatewayRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroGatewayRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroGatewayRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp6 }
        \cup { [ZeroGatewayRequest EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroGatewayRequest EXCEPT !.defaultCstmApplVerId = one] : one \in Sample(30) }
        \cup { [ZeroGatewayRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroGatewayRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Heartbeat: 10 bytes                                                     *)
(***************************************************************************)

Heartbeat ==
    [ networkMsgId : Sample(8),
      pad2         : Sample(2) ]

EncodeHeartbeat(message) ==
    message.networkMsgId
        \o message.pad2

DecodeHeartbeat(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    Ok([ networkMsgId |-> networkMsgId.value,
         pad2         |-> pad2.value ], pad2.rest)

ZeroHeartbeat ==
    [ networkMsgId |-> [i \in 1 .. 8 |-> 0],
      pad2         |-> [i \in 1 .. 2 |-> 0] ]

(* Heartbeat at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeat ==
    { ZeroHeartbeat }
        \cup { [ZeroHeartbeat EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroHeartbeat EXCEPT !.pad2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp7 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp7(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp7(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp7 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp7 ==
    { ZeroRequestHeaderComp7 }
        \cup { [ZeroRequestHeaderComp7 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp7 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Inquire Session List Request: 18 bytes                                  *)
(***************************************************************************)

InquireSessionListRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp7 ]

EncodeInquireSessionListRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp7(message.requestHeaderComp)

DecodeInquireSessionListRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp7(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroInquireSessionListRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp7 ]

(* Inquire Session List Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireSessionListRequest ==
    { ZeroInquireSessionListRequest }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp7 }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp8 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp8(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp8(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp8 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp8 ==
    { ZeroRequestHeaderComp8 }
        \cup { [ZeroRequestHeaderComp8 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp8 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Request: 274 bytes                                                *)
(***************************************************************************)

LogonRequest ==
    [ networkMsgId             : Sample(8),
      pad2                     : Sample(2),
      requestHeaderComp        : RequestHeaderComp8,
      heartBtInt               : Sample(4),
      partyIdSessionId         : Sample(4),
      defaultCstmApplVerId     : Sample(30),
      password                 : Sample(32),
      applUsageOrders          : Sample(1),
      applUsageQuotes          : Sample(1),
      orderRoutingIndicator    : Sample(1),
      fixEngineName            : Sample(30),
      fixEngineVersion         : Sample(30),
      fixEngineVendor          : Sample(30),
      applicationSystemName    : Sample(30),
      applicationSystemVersion : Sample(30),
      applicationSystemVendor  : Sample(30),
      pad3                     : Sample(3) ]

EncodeLogonRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp8(message.requestHeaderComp)
        \o message.heartBtInt
        \o message.partyIdSessionId
        \o message.defaultCstmApplVerId
        \o message.password
        \o message.applUsageOrders
        \o message.applUsageQuotes
        \o message.orderRoutingIndicator
        \o message.fixEngineName
        \o message.fixEngineVersion
        \o message.fixEngineVendor
        \o message.applicationSystemName
        \o message.applicationSystemVersion
        \o message.applicationSystemVendor
        \o message.pad3

DecodeLogonRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp8(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(requestHeaderComp.rest, 4) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(heartBtInt.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET defaultCstmApplVerId == ReadBytes(partyIdSessionId.rest, 30) IN IF ~defaultCstmApplVerId.ok THEN Fail ELSE
    LET password == ReadBytes(defaultCstmApplVerId.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET applUsageOrders == ReadBytes(password.rest, 1) IN IF ~applUsageOrders.ok THEN Fail ELSE
    LET applUsageQuotes == ReadBytes(applUsageOrders.rest, 1) IN IF ~applUsageQuotes.ok THEN Fail ELSE
    LET orderRoutingIndicator == ReadBytes(applUsageQuotes.rest, 1) IN IF ~orderRoutingIndicator.ok THEN Fail ELSE
    LET fixEngineName == ReadBytes(orderRoutingIndicator.rest, 30) IN IF ~fixEngineName.ok THEN Fail ELSE
    LET fixEngineVersion == ReadBytes(fixEngineName.rest, 30) IN IF ~fixEngineVersion.ok THEN Fail ELSE
    LET fixEngineVendor == ReadBytes(fixEngineVersion.rest, 30) IN IF ~fixEngineVendor.ok THEN Fail ELSE
    LET applicationSystemName == ReadBytes(fixEngineVendor.rest, 30) IN IF ~applicationSystemName.ok THEN Fail ELSE
    LET applicationSystemVersion == ReadBytes(applicationSystemName.rest, 30) IN IF ~applicationSystemVersion.ok THEN Fail ELSE
    LET applicationSystemVendor == ReadBytes(applicationSystemVersion.rest, 30) IN IF ~applicationSystemVendor.ok THEN Fail ELSE
    LET pad3 == ReadBytes(applicationSystemVendor.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ networkMsgId             |-> networkMsgId.value,
         pad2                     |-> pad2.value,
         requestHeaderComp        |-> requestHeaderComp.value,
         heartBtInt               |-> heartBtInt.value,
         partyIdSessionId         |-> partyIdSessionId.value,
         defaultCstmApplVerId     |-> defaultCstmApplVerId.value,
         password                 |-> password.value,
         applUsageOrders          |-> applUsageOrders.value,
         applUsageQuotes          |-> applUsageQuotes.value,
         orderRoutingIndicator    |-> orderRoutingIndicator.value,
         fixEngineName            |-> fixEngineName.value,
         fixEngineVersion         |-> fixEngineVersion.value,
         fixEngineVendor          |-> fixEngineVendor.value,
         applicationSystemName    |-> applicationSystemName.value,
         applicationSystemVersion |-> applicationSystemVersion.value,
         applicationSystemVendor  |-> applicationSystemVendor.value,
         pad3                     |-> pad3.value ], pad3.rest)

ZeroLogonRequest ==
    [ networkMsgId             |-> [i \in 1 .. 8 |-> 0],
      pad2                     |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp        |-> ZeroRequestHeaderComp8,
      heartBtInt               |-> [i \in 1 .. 4 |-> 0],
      partyIdSessionId         |-> [i \in 1 .. 4 |-> 0],
      defaultCstmApplVerId     |-> [i \in 1 .. 30 |-> 0],
      password                 |-> [i \in 1 .. 32 |-> 0],
      applUsageOrders          |-> [i \in 1 .. 1 |-> 0],
      applUsageQuotes          |-> [i \in 1 .. 1 |-> 0],
      orderRoutingIndicator    |-> [i \in 1 .. 1 |-> 0],
      fixEngineName            |-> [i \in 1 .. 30 |-> 0],
      fixEngineVersion         |-> [i \in 1 .. 30 |-> 0],
      fixEngineVendor          |-> [i \in 1 .. 30 |-> 0],
      applicationSystemName    |-> [i \in 1 .. 30 |-> 0],
      applicationSystemVersion |-> [i \in 1 .. 30 |-> 0],
      applicationSystemVendor  |-> [i \in 1 .. 30 |-> 0],
      pad3                     |-> [i \in 1 .. 3 |-> 0] ]

(* Logon Request at zero, then each field in turn at the values it is checked at *)
CheckedLogonRequest ==
    { ZeroLogonRequest }
        \cup { [ZeroLogonRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogonRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp8 }
        \cup { [ZeroLogonRequest EXCEPT !.heartBtInt = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequest EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequest EXCEPT !.defaultCstmApplVerId = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroLogonRequest EXCEPT !.applUsageOrders = one] : one \in Sample(1) }
        \cup { [ZeroLogonRequest EXCEPT !.applUsageQuotes = one] : one \in Sample(1) }
        \cup { [ZeroLogonRequest EXCEPT !.orderRoutingIndicator = one] : one \in Sample(1) }
        \cup { [ZeroLogonRequest EXCEPT !.fixEngineName = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequest EXCEPT !.fixEngineVersion = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequest EXCEPT !.fixEngineVendor = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequest EXCEPT !.applicationSystemName = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequest EXCEPT !.applicationSystemVersion = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequest EXCEPT !.applicationSystemVendor = one] : one \in Sample(30) }
        \cup { [ZeroLogonRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp9 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp9(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp9(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp9 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp9 ==
    { ZeroRequestHeaderComp9 }
        \cup { [ZeroRequestHeaderComp9 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp9 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout Request: 18 bytes                                                *)
(***************************************************************************)

LogoutRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp9 ]

EncodeLogoutRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp9(message.requestHeaderComp)

DecodeLogoutRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp9(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroLogoutRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp9 ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroLogoutRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogoutRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp9 }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp10 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp10(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp10(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp10 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp10 ==
    { ZeroRequestHeaderComp10 }
        \cup { [ZeroRequestHeaderComp10 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp10 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Entry Grp Comp: 40 bytes                                          *)
(***************************************************************************)

QuoteEntryGrpComp ==
    [ securityId : Sample(8),
      bidPx      : Sample(8),
      offerPx    : Sample(8),
      bidSize    : Sample(4),
      offerSize  : Sample(4),
      messageTag : Sample(4),
      pad4       : Sample(4) ]

EncodeQuoteEntryGrpComp(message) ==
    message.securityId
        \o message.bidPx
        \o message.offerPx
        \o message.bidSize
        \o message.offerSize
        \o message.messageTag
        \o message.pad4

DecodeQuoteEntryGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(offerPx.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    LET messageTag == ReadBytes(offerSize.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET pad4 == ReadBytes(messageTag.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         bidPx      |-> bidPx.value,
         offerPx    |-> offerPx.value,
         bidSize    |-> bidSize.value,
         offerSize  |-> offerSize.value,
         messageTag |-> messageTag.value,
         pad4       |-> pad4.value ], pad4.rest)

ZeroQuoteEntryGrpComp ==
    [ securityId |-> [i \in 1 .. 8 |-> 0],
      bidPx      |-> [i \in 1 .. 8 |-> 0],
      offerPx    |-> [i \in 1 .. 8 |-> 0],
      bidSize    |-> [i \in 1 .. 4 |-> 0],
      offerSize  |-> [i \in 1 .. 4 |-> 0],
      messageTag |-> [i \in 1 .. 4 |-> 0],
      pad4       |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Entry Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEntryGrpComp ==
    { ZeroQuoteEntryGrpComp }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.offerSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Quote Entry Grp Comp, written one after another *)
RECURSIVE EncodeQuoteEntryGrpCompList(_)
EncodeQuoteEntryGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteEntryGrpComp(Head(messages)) \o EncodeQuoteEntryGrpCompList(Tail(messages))

(* As many Quote Entry Grp Comp as the field that counts them says *)
RECURSIVE ReadQuoteEntryGrpCompList(_, _)
ReadQuoteEntryGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteEntryGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteEntryGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Entry Grp Comp of each kind, for the lists that carry them *)
OneQuoteEntryGrpComp == { ZeroQuoteEntryGrpComp }

(***************************************************************************)
(* Mass Quote Request                                                      *)
(***************************************************************************)

MassQuoteRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp10,
      senderLocationId       : Sample(8),
      quoteId                : Sample(8),
      marketSegmentId        : Sample(4),
      regulatoryId           : Sample(4),
      enrichmentRuleId       : Sample(2),
      accountType            : Sample(1),
      priceValidityCheckType : Sample(1),
      quoteSizeType          : Sample(1),
      stpcFlag               : Sample(1),
      algoId                 : Sample(16),
      clientCode             : Sample(12),
      cpCode                 : Sample(12),
      pad1                   : Sample(1),
      quoteEntryGrpComp      : SampleLists(OneQuoteEntryGrpComp) ]

EncodeMassQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp10(message.requestHeaderComp)
        \o message.senderLocationId
        \o message.quoteId
        \o message.marketSegmentId
        \o message.regulatoryId
        \o message.enrichmentRuleId
        \o message.accountType
        \o message.priceValidityCheckType
        \o message.quoteSizeType
        \o message.stpcFlag
        \o EncodeUIntBE(Len(message.quoteEntryGrpComp), 1)
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.pad1
        \o EncodeQuoteEntryGrpCompList(message.quoteEntryGrpComp)

DecodeMassQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp10(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(senderLocationId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET regulatoryId == ReadBytes(marketSegmentId.rest, 4) IN IF ~regulatoryId.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(regulatoryId.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET accountType == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(accountType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET quoteSizeType == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~quoteSizeType.ok THEN Fail ELSE
    LET stpcFlag == ReadBytes(quoteSizeType.rest, 1) IN IF ~stpcFlag.ok THEN Fail ELSE
    LET noQuoteEntries == ReadUIntBE(stpcFlag.rest, 1) IN IF ~noQuoteEntries.ok THEN Fail ELSE
    LET algoId == ReadBytes(noQuoteEntries.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET pad1 == ReadBytes(cpCode.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET quoteEntryGrpComp == ReadQuoteEntryGrpCompList(pad1.rest, noQuoteEntries.value) IN IF ~quoteEntryGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         senderLocationId       |-> senderLocationId.value,
         quoteId                |-> quoteId.value,
         marketSegmentId        |-> marketSegmentId.value,
         regulatoryId           |-> regulatoryId.value,
         enrichmentRuleId       |-> enrichmentRuleId.value,
         accountType            |-> accountType.value,
         priceValidityCheckType |-> priceValidityCheckType.value,
         quoteSizeType          |-> quoteSizeType.value,
         stpcFlag               |-> stpcFlag.value,
         algoId                 |-> algoId.value,
         clientCode             |-> clientCode.value,
         cpCode                 |-> cpCode.value,
         pad1                   |-> pad1.value,
         quoteEntryGrpComp      |-> quoteEntryGrpComp.value ], quoteEntryGrpComp.rest)

ZeroMassQuoteRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp10,
      senderLocationId       |-> [i \in 1 .. 8 |-> 0],
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      regulatoryId           |-> [i \in 1 .. 4 |-> 0],
      enrichmentRuleId       |-> [i \in 1 .. 2 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType |-> [i \in 1 .. 1 |-> 0],
      quoteSizeType          |-> [i \in 1 .. 1 |-> 0],
      stpcFlag               |-> [i \in 1 .. 1 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      clientCode             |-> [i \in 1 .. 12 |-> 0],
      cpCode                 |-> [i \in 1 .. 12 |-> 0],
      pad1                   |-> [i \in 1 .. 1 |-> 0],
      quoteEntryGrpComp      |-> << >> ]

(* Mass Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequest ==
    { ZeroMassQuoteRequest }
        \cup { [ZeroMassQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp10 }
        \cup { [ZeroMassQuoteRequest EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.regulatoryId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteSizeType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.stpcFlag = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteEntryGrpComp = one] : one \in SampleLists(OneQuoteEntryGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp11 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp11(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp11(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp11 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp11 ==
    { ZeroRequestHeaderComp11 }
        \cup { [ZeroRequestHeaderComp11 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp11 EXCEPT !.senderSubId = one] : one \in Sample(4) }

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
(* Modify Order Complex Request                                            *)
(***************************************************************************)

ModifyOrderComplexRequest ==
    [ networkMsgId                : Sample(8),
      pad2                        : Sample(2),
      requestHeaderComp           : RequestHeaderComp11,
      orderId                     : Sample(8),
      clOrdId                     : Sample(8),
      origClOrdId                 : Sample(8),
      securityId                  : Sample(8),
      price                       : Sample(8),
      maxPricePercentage          : Sample(8),
      senderLocationId            : Sample(8),
      activityTime                : Sample(8),
      filler1                     : Sample(8),
      filler2                     : Sample(4),
      marketSegmentId             : Sample(4),
      messageTag                  : Sample(4),
      orderQty                    : Sample(4),
      maxShow                     : Sample(4),
      expireDate                  : Sample(4),
      targetPartyIdSessionId      : Sample(4),
      regulatoryId                : Sample(4),
      filler4                     : Sample(2),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      accountType                 : Sample(1),
      applSeqIndicator            : Sample(1),
      productComplex              : Sample(1),
      side                        : Sample(1),
      ordType                     : Sample(1),
      priceValidityCheckType      : Sample(1),
      execInst                    : Sample(1),
      timeInForce                 : Sample(1),
      rolloverFlag                : Sample(1),
      tradingCapacity             : Sample(1),
      deltaQtyFlag                : Sample(1),
      partyIdLocationId           : Sample(2),
      custOrderHandlingInst       : Sample(1),
      regulatoryText              : Sample(20),
      algoId                      : Sample(16),
      clientCode                  : Sample(12),
      cpCode                      : Sample(12),
      freeText3                   : Sample(12),
      pad2v2                      : Sample(2),
      legOrdGrpComp               : SampleLists(OneLegOrdGrpComp) ]

EncodeModifyOrderComplexRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp11(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.price
        \o message.maxPricePercentage
        \o message.senderLocationId
        \o message.activityTime
        \o message.filler1
        \o message.filler2
        \o message.marketSegmentId
        \o message.messageTag
        \o message.orderQty
        \o message.maxShow
        \o message.expireDate
        \o message.targetPartyIdSessionId
        \o message.regulatoryId
        \o message.filler4
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.accountType
        \o message.applSeqIndicator
        \o message.productComplex
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.execInst
        \o message.timeInForce
        \o message.rolloverFlag
        \o message.tradingCapacity
        \o message.deltaQtyFlag
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.regulatoryText
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.freeText3
        \o EncodeUIntBE(Len(message.legOrdGrpComp), 1)
        \o message.pad2v2
        \o EncodeLegOrdGrpCompList(message.legOrdGrpComp)

DecodeModifyOrderComplexRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp11(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET maxPricePercentage == ReadBytes(price.rest, 8) IN IF ~maxPricePercentage.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(maxPricePercentage.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET activityTime == ReadBytes(senderLocationId.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(activityTime.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(filler2.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET messageTag == ReadBytes(marketSegmentId.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET orderQty == ReadBytes(messageTag.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET maxShow == ReadBytes(orderQty.rest, 4) IN IF ~maxShow.ok THEN Fail ELSE
    LET expireDate == ReadBytes(maxShow.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(expireDate.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET regulatoryId == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~regulatoryId.ok THEN Fail ELSE
    LET filler4 == ReadBytes(regulatoryId.rest, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(filler4.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET accountType == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(accountType.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET productComplex == ReadBytes(applSeqIndicator.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET side == ReadBytes(productComplex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET execInst == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(execInst.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(timeInForce.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(rolloverFlag.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET deltaQtyFlag == ReadBytes(tradingCapacity.rest, 1) IN IF ~deltaQtyFlag.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(deltaQtyFlag.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET regulatoryText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~regulatoryText.ok THEN Fail ELSE
    LET algoId == ReadBytes(regulatoryText.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(cpCode.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(freeText3.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(noLegs.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET legOrdGrpComp == ReadLegOrdGrpCompList(pad2v2.rest, noLegs.value) IN IF ~legOrdGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                |-> networkMsgId.value,
         pad2                        |-> pad2.value,
         requestHeaderComp           |-> requestHeaderComp.value,
         orderId                     |-> orderId.value,
         clOrdId                     |-> clOrdId.value,
         origClOrdId                 |-> origClOrdId.value,
         securityId                  |-> securityId.value,
         price                       |-> price.value,
         maxPricePercentage          |-> maxPricePercentage.value,
         senderLocationId            |-> senderLocationId.value,
         activityTime                |-> activityTime.value,
         filler1                     |-> filler1.value,
         filler2                     |-> filler2.value,
         marketSegmentId             |-> marketSegmentId.value,
         messageTag                  |-> messageTag.value,
         orderQty                    |-> orderQty.value,
         maxShow                     |-> maxShow.value,
         expireDate                  |-> expireDate.value,
         targetPartyIdSessionId      |-> targetPartyIdSessionId.value,
         regulatoryId                |-> regulatoryId.value,
         filler4                     |-> filler4.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         accountType                 |-> accountType.value,
         applSeqIndicator            |-> applSeqIndicator.value,
         productComplex              |-> productComplex.value,
         side                        |-> side.value,
         ordType                     |-> ordType.value,
         priceValidityCheckType      |-> priceValidityCheckType.value,
         execInst                    |-> execInst.value,
         timeInForce                 |-> timeInForce.value,
         rolloverFlag                |-> rolloverFlag.value,
         tradingCapacity             |-> tradingCapacity.value,
         deltaQtyFlag                |-> deltaQtyFlag.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         regulatoryText              |-> regulatoryText.value,
         algoId                      |-> algoId.value,
         clientCode                  |-> clientCode.value,
         cpCode                      |-> cpCode.value,
         freeText3                   |-> freeText3.value,
         pad2v2                      |-> pad2v2.value,
         legOrdGrpComp               |-> legOrdGrpComp.value ], legOrdGrpComp.rest)

ZeroModifyOrderComplexRequest ==
    [ networkMsgId                |-> [i \in 1 .. 8 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp           |-> ZeroRequestHeaderComp11,
      orderId                     |-> [i \in 1 .. 8 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                 |-> [i \in 1 .. 8 |-> 0],
      securityId                  |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      maxPricePercentage          |-> [i \in 1 .. 8 |-> 0],
      senderLocationId            |-> [i \in 1 .. 8 |-> 0],
      activityTime                |-> [i \in 1 .. 8 |-> 0],
      filler1                     |-> [i \in 1 .. 8 |-> 0],
      filler2                     |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      messageTag                  |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      maxShow                     |-> [i \in 1 .. 4 |-> 0],
      expireDate                  |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId      |-> [i \in 1 .. 4 |-> 0],
      regulatoryId                |-> [i \in 1 .. 4 |-> 0],
      filler4                     |-> [i \in 1 .. 2 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      accountType                 |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator            |-> [i \in 1 .. 1 |-> 0],
      productComplex              |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      ordType                     |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType      |-> [i \in 1 .. 1 |-> 0],
      execInst                    |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag                |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      deltaQtyFlag                |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      regulatoryText              |-> [i \in 1 .. 20 |-> 0],
      algoId                      |-> [i \in 1 .. 16 |-> 0],
      clientCode                  |-> [i \in 1 .. 12 |-> 0],
      cpCode                      |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      pad2v2                      |-> [i \in 1 .. 2 |-> 0],
      legOrdGrpComp               |-> << >> ]

(* Modify Order Complex Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderComplexRequest ==
    { ZeroModifyOrderComplexRequest }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp11 }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.maxPricePercentage = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.maxShow = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.regulatoryId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.deltaQtyFlag = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.regulatoryText = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.legOrdGrpComp = one] : one \in SampleLists(OneLegOrdGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp12 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp12(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp12(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp12 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp12 ==
    { ZeroRequestHeaderComp12 }
        \cup { [ZeroRequestHeaderComp12 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp12 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Single Request: 242 bytes                                  *)
(***************************************************************************)

ModifyOrderSingleRequest ==
    [ networkMsgId                : Sample(8),
      pad2                        : Sample(2),
      requestHeaderComp           : RequestHeaderComp12,
      orderId                     : Sample(8),
      clOrdId                     : Sample(8),
      origClOrdId                 : Sample(8),
      price                       : Sample(8),
      stopPx                      : Sample(8),
      maxPricePercentage          : Sample(8),
      senderLocationId            : Sample(8),
      activityTime                : Sample(8),
      filler1                     : Sample(8),
      filler2                     : Sample(4),
      messageTag                  : Sample(4),
      orderQty                    : Sample(4),
      maxShow                     : Sample(4),
      expireDate                  : Sample(4),
      marketSegmentId             : Sample(4),
      simpleSecurityId            : Sample(4),
      targetPartyIdSessionId      : Sample(4),
      regulatoryId                : Sample(4),
      filler4                     : Sample(2),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      accountType                 : Sample(1),
      applSeqIndicator            : Sample(1),
      side                        : Sample(1),
      ordType                     : Sample(1),
      priceValidityCheckType      : Sample(1),
      timeInForce                 : Sample(1),
      execInst                    : Sample(1),
      rolloverFlag                : Sample(1),
      tradingSessionSubId         : Sample(1),
      tradingCapacity             : Sample(1),
      deltaQtyFlag                : Sample(1),
      account                     : Sample(2),
      positionEffect              : Sample(1),
      partyIdLocationId           : Sample(2),
      custOrderHandlingInst       : Sample(1),
      regulatoryText              : Sample(20),
      algoId                      : Sample(16),
      clientCode                  : Sample(12),
      cpCode                      : Sample(12),
      freeText3                   : Sample(12),
      pad4                        : Sample(4) ]

EncodeModifyOrderSingleRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp12(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.price
        \o message.stopPx
        \o message.maxPricePercentage
        \o message.senderLocationId
        \o message.activityTime
        \o message.filler1
        \o message.filler2
        \o message.messageTag
        \o message.orderQty
        \o message.maxShow
        \o message.expireDate
        \o message.marketSegmentId
        \o message.simpleSecurityId
        \o message.targetPartyIdSessionId
        \o message.regulatoryId
        \o message.filler4
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.accountType
        \o message.applSeqIndicator
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.timeInForce
        \o message.execInst
        \o message.rolloverFlag
        \o message.tradingSessionSubId
        \o message.tradingCapacity
        \o message.deltaQtyFlag
        \o message.account
        \o message.positionEffect
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.regulatoryText
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.freeText3
        \o message.pad4

DecodeModifyOrderSingleRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp12(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET maxPricePercentage == ReadBytes(stopPx.rest, 8) IN IF ~maxPricePercentage.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(maxPricePercentage.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET activityTime == ReadBytes(senderLocationId.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET filler1 == ReadBytes(activityTime.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET messageTag == ReadBytes(filler2.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET orderQty == ReadBytes(messageTag.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET maxShow == ReadBytes(orderQty.rest, 4) IN IF ~maxShow.ok THEN Fail ELSE
    LET expireDate == ReadBytes(maxShow.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(expireDate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(marketSegmentId.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(simpleSecurityId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET regulatoryId == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~regulatoryId.ok THEN Fail ELSE
    LET filler4 == ReadBytes(regulatoryId.rest, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(filler4.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET accountType == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(accountType.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(applSeqIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(execInst.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(rolloverFlag.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET deltaQtyFlag == ReadBytes(tradingCapacity.rest, 1) IN IF ~deltaQtyFlag.ok THEN Fail ELSE
    LET account == ReadBytes(deltaQtyFlag.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(account.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(positionEffect.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET regulatoryText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~regulatoryText.ok THEN Fail ELSE
    LET algoId == ReadBytes(regulatoryText.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(cpCode.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET pad4 == ReadBytes(freeText3.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId                |-> networkMsgId.value,
         pad2                        |-> pad2.value,
         requestHeaderComp           |-> requestHeaderComp.value,
         orderId                     |-> orderId.value,
         clOrdId                     |-> clOrdId.value,
         origClOrdId                 |-> origClOrdId.value,
         price                       |-> price.value,
         stopPx                      |-> stopPx.value,
         maxPricePercentage          |-> maxPricePercentage.value,
         senderLocationId            |-> senderLocationId.value,
         activityTime                |-> activityTime.value,
         filler1                     |-> filler1.value,
         filler2                     |-> filler2.value,
         messageTag                  |-> messageTag.value,
         orderQty                    |-> orderQty.value,
         maxShow                     |-> maxShow.value,
         expireDate                  |-> expireDate.value,
         marketSegmentId             |-> marketSegmentId.value,
         simpleSecurityId            |-> simpleSecurityId.value,
         targetPartyIdSessionId      |-> targetPartyIdSessionId.value,
         regulatoryId                |-> regulatoryId.value,
         filler4                     |-> filler4.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         accountType                 |-> accountType.value,
         applSeqIndicator            |-> applSeqIndicator.value,
         side                        |-> side.value,
         ordType                     |-> ordType.value,
         priceValidityCheckType      |-> priceValidityCheckType.value,
         timeInForce                 |-> timeInForce.value,
         execInst                    |-> execInst.value,
         rolloverFlag                |-> rolloverFlag.value,
         tradingSessionSubId         |-> tradingSessionSubId.value,
         tradingCapacity             |-> tradingCapacity.value,
         deltaQtyFlag                |-> deltaQtyFlag.value,
         account                     |-> account.value,
         positionEffect              |-> positionEffect.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         regulatoryText              |-> regulatoryText.value,
         algoId                      |-> algoId.value,
         clientCode                  |-> clientCode.value,
         cpCode                      |-> cpCode.value,
         freeText3                   |-> freeText3.value,
         pad4                        |-> pad4.value ], pad4.rest)

ZeroModifyOrderSingleRequest ==
    [ networkMsgId                |-> [i \in 1 .. 8 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp           |-> ZeroRequestHeaderComp12,
      orderId                     |-> [i \in 1 .. 8 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                 |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      stopPx                      |-> [i \in 1 .. 8 |-> 0],
      maxPricePercentage          |-> [i \in 1 .. 8 |-> 0],
      senderLocationId            |-> [i \in 1 .. 8 |-> 0],
      activityTime                |-> [i \in 1 .. 8 |-> 0],
      filler1                     |-> [i \in 1 .. 8 |-> 0],
      filler2                     |-> [i \in 1 .. 4 |-> 0],
      messageTag                  |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      maxShow                     |-> [i \in 1 .. 4 |-> 0],
      expireDate                  |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId            |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId      |-> [i \in 1 .. 4 |-> 0],
      regulatoryId                |-> [i \in 1 .. 4 |-> 0],
      filler4                     |-> [i \in 1 .. 2 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      accountType                 |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator            |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      ordType                     |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType      |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      execInst                    |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag                |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId         |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      deltaQtyFlag                |-> [i \in 1 .. 1 |-> 0],
      account                     |-> [i \in 1 .. 2 |-> 0],
      positionEffect              |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      regulatoryText              |-> [i \in 1 .. 20 |-> 0],
      algoId                      |-> [i \in 1 .. 16 |-> 0],
      clientCode                  |-> [i \in 1 .. 12 |-> 0],
      cpCode                      |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      pad4                        |-> [i \in 1 .. 4 |-> 0] ]

(* Modify Order Single Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderSingleRequest ==
    { ZeroModifyOrderSingleRequest }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp12 }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.maxPricePercentage = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.maxShow = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.regulatoryId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.deltaQtyFlag = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.regulatoryText = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp13 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp13(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp13(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp13 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp13 ==
    { ZeroRequestHeaderComp13 }
        \cup { [ZeroRequestHeaderComp13 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp13 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Single Short Request: 130 bytes                            *)
(***************************************************************************)

ModifyOrderSingleShortRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp13,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      price                  : Sample(8),
      senderLocationId       : Sample(8),
      activityTime           : Sample(8),
      orderQty               : Sample(4),
      maxShow                : Sample(4),
      simpleSecurityId       : Sample(4),
      filler2                : Sample(4),
      filler4                : Sample(2),
      accountType            : Sample(1),
      side                   : Sample(1),
      priceValidityCheckType : Sample(1),
      timeInForce            : Sample(1),
      execInst               : Sample(1),
      algoId                 : Sample(16),
      clientCode             : Sample(12),
      cpCode                 : Sample(12),
      pad1                   : Sample(1) ]

EncodeModifyOrderSingleShortRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp13(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.price
        \o message.senderLocationId
        \o message.activityTime
        \o message.orderQty
        \o message.maxShow
        \o message.simpleSecurityId
        \o message.filler2
        \o message.filler4
        \o message.accountType
        \o message.side
        \o message.priceValidityCheckType
        \o message.timeInForce
        \o message.execInst
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.pad1

DecodeModifyOrderSingleShortRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp13(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(price.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET activityTime == ReadBytes(senderLocationId.rest, 8) IN IF ~activityTime.ok THEN Fail ELSE
    LET orderQty == ReadBytes(activityTime.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET maxShow == ReadBytes(orderQty.rest, 4) IN IF ~maxShow.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(maxShow.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET filler2 == ReadBytes(simpleSecurityId.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET filler4 == ReadBytes(filler2.rest, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET accountType == ReadBytes(filler4.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET side == ReadBytes(accountType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(side.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET algoId == ReadBytes(execInst.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET pad1 == ReadBytes(cpCode.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         price                  |-> price.value,
         senderLocationId       |-> senderLocationId.value,
         activityTime           |-> activityTime.value,
         orderQty               |-> orderQty.value,
         maxShow                |-> maxShow.value,
         simpleSecurityId       |-> simpleSecurityId.value,
         filler2                |-> filler2.value,
         filler4                |-> filler4.value,
         accountType            |-> accountType.value,
         side                   |-> side.value,
         priceValidityCheckType |-> priceValidityCheckType.value,
         timeInForce            |-> timeInForce.value,
         execInst               |-> execInst.value,
         algoId                 |-> algoId.value,
         clientCode             |-> clientCode.value,
         cpCode                 |-> cpCode.value,
         pad1                   |-> pad1.value ], pad1.rest)

ZeroModifyOrderSingleShortRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp13,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      senderLocationId       |-> [i \in 1 .. 8 |-> 0],
      activityTime           |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      maxShow                |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId       |-> [i \in 1 .. 4 |-> 0],
      filler2                |-> [i \in 1 .. 4 |-> 0],
      filler4                |-> [i \in 1 .. 2 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType |-> [i \in 1 .. 1 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      clientCode             |-> [i \in 1 .. 12 |-> 0],
      cpCode                 |-> [i \in 1 .. 12 |-> 0],
      pad1                   |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Single Short Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderSingleShortRequest ==
    { ZeroModifyOrderSingleShortRequest }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp13 }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.activityTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.maxShow = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp14 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp14(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp14(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp14 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp14 ==
    { ZeroRequestHeaderComp14 }
        \cup { [ZeroRequestHeaderComp14 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp14 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Multi Leg Ord Grp Comp: 40 bytes                                        *)
(***************************************************************************)

MultiLegOrdGrpComp ==
    [ securityId         : Sample(8),
      price              : Sample(8),
      maxPricePercentage : Sample(8),
      messageTag         : Sample(4),
      marketSegmentId    : Sample(4),
      orderQty           : Sample(4),
      productComplex     : Sample(1),
      side               : Sample(1),
      ordType            : Sample(1),
      pad1               : Sample(1) ]

EncodeMultiLegOrdGrpComp(message) ==
    message.securityId
        \o message.price
        \o message.maxPricePercentage
        \o message.messageTag
        \o message.marketSegmentId
        \o message.orderQty
        \o message.productComplex
        \o message.side
        \o message.ordType
        \o message.pad1

DecodeMultiLegOrdGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET maxPricePercentage == ReadBytes(price.rest, 8) IN IF ~maxPricePercentage.ok THEN Fail ELSE
    LET messageTag == ReadBytes(maxPricePercentage.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(messageTag.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET productComplex == ReadBytes(orderQty.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET side == ReadBytes(productComplex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET pad1 == ReadBytes(ordType.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ securityId         |-> securityId.value,
         price              |-> price.value,
         maxPricePercentage |-> maxPricePercentage.value,
         messageTag         |-> messageTag.value,
         marketSegmentId    |-> marketSegmentId.value,
         orderQty           |-> orderQty.value,
         productComplex     |-> productComplex.value,
         side               |-> side.value,
         ordType            |-> ordType.value,
         pad1               |-> pad1.value ], pad1.rest)

ZeroMultiLegOrdGrpComp ==
    [ securityId         |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      maxPricePercentage |-> [i \in 1 .. 8 |-> 0],
      messageTag         |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      orderQty           |-> [i \in 1 .. 4 |-> 0],
      productComplex     |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      ordType            |-> [i \in 1 .. 1 |-> 0],
      pad1               |-> [i \in 1 .. 1 |-> 0] ]

(* Multi Leg Ord Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegOrdGrpComp ==
    { ZeroMultiLegOrdGrpComp }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.maxPricePercentage = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegOrdGrpComp EXCEPT !.pad1 = one] : one \in Sample(1) }

(* A run of Multi Leg Ord Grp Comp, written one after another *)
RECURSIVE EncodeMultiLegOrdGrpCompList(_)
EncodeMultiLegOrdGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMultiLegOrdGrpComp(Head(messages)) \o EncodeMultiLegOrdGrpCompList(Tail(messages))

(* As many Multi Leg Ord Grp Comp as the field that counts them says *)
RECURSIVE ReadMultiLegOrdGrpCompList(_, _)
ReadMultiLegOrdGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMultiLegOrdGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMultiLegOrdGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Multi Leg Ord Grp Comp of each kind, for the lists that carry them *)
OneMultiLegOrdGrpComp == { ZeroMultiLegOrdGrpComp }

(***************************************************************************)
(* Multi Leg Order Request                                                 *)
(***************************************************************************)

MultiLegOrderRequest ==
    [ networkMsgId       : Sample(8),
      pad2               : Sample(2),
      requestHeaderComp  : RequestHeaderComp14,
      senderLocationId   : Sample(8),
      clOrdId            : Sample(8),
      accountType        : Sample(1),
      allOrNoneFlag      : Sample(1),
      algoId             : Sample(16),
      clientCode         : Sample(12),
      cpCode             : Sample(12),
      pad5               : Sample(5),
      multiLegOrdGrpComp : SampleLists(OneMultiLegOrdGrpComp) ]

EncodeMultiLegOrderRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp14(message.requestHeaderComp)
        \o message.senderLocationId
        \o message.clOrdId
        \o message.accountType
        \o message.allOrNoneFlag
        \o EncodeUIntBE(Len(message.multiLegOrdGrpComp), 1)
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.pad5
        \o EncodeMultiLegOrdGrpCompList(message.multiLegOrdGrpComp)

DecodeMultiLegOrderRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp14(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(senderLocationId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET accountType == ReadBytes(clOrdId.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET allOrNoneFlag == ReadBytes(accountType.rest, 1) IN IF ~allOrNoneFlag.ok THEN Fail ELSE
    LET noOfMultiLeg == ReadUIntBE(allOrNoneFlag.rest, 1) IN IF ~noOfMultiLeg.ok THEN Fail ELSE
    LET algoId == ReadBytes(noOfMultiLeg.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET pad5 == ReadBytes(cpCode.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    LET multiLegOrdGrpComp == ReadMultiLegOrdGrpCompList(pad5.rest, noOfMultiLeg.value) IN IF ~multiLegOrdGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId       |-> networkMsgId.value,
         pad2               |-> pad2.value,
         requestHeaderComp  |-> requestHeaderComp.value,
         senderLocationId   |-> senderLocationId.value,
         clOrdId            |-> clOrdId.value,
         accountType        |-> accountType.value,
         allOrNoneFlag      |-> allOrNoneFlag.value,
         algoId             |-> algoId.value,
         clientCode         |-> clientCode.value,
         cpCode             |-> cpCode.value,
         pad5               |-> pad5.value,
         multiLegOrdGrpComp |-> multiLegOrdGrpComp.value ], multiLegOrdGrpComp.rest)

ZeroMultiLegOrderRequest ==
    [ networkMsgId       |-> [i \in 1 .. 8 |-> 0],
      pad2               |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp  |-> ZeroRequestHeaderComp14,
      senderLocationId   |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 8 |-> 0],
      accountType        |-> [i \in 1 .. 1 |-> 0],
      allOrNoneFlag      |-> [i \in 1 .. 1 |-> 0],
      algoId             |-> [i \in 1 .. 16 |-> 0],
      clientCode         |-> [i \in 1 .. 12 |-> 0],
      cpCode             |-> [i \in 1 .. 12 |-> 0],
      pad5               |-> [i \in 1 .. 5 |-> 0],
      multiLegOrdGrpComp |-> << >> ]

(* Multi Leg Order Request at zero, then each field in turn at the values it is checked at *)
CheckedMultiLegOrderRequest ==
    { ZeroMultiLegOrderRequest }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp14 }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.allOrNoneFlag = one] : one \in Sample(1) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.pad5 = one] : one \in Sample(5) }
        \cup { [ZeroMultiLegOrderRequest EXCEPT !.multiLegOrdGrpComp = one] : one \in SampleLists(OneMultiLegOrdGrpComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp15 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp15(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp15(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp15 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp15 ==
    { ZeroRequestHeaderComp15 }
        \cup { [ZeroRequestHeaderComp15 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp15 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg Ord Grp Comp: 8 bytes                                               *)
(***************************************************************************)

LegOrdGrpComp2 ==
    [ legAccount        : Sample(2),
      legPositionEffect : Sample(1),
      pad5              : Sample(5) ]

EncodeLegOrdGrpComp2(message) ==
    message.legAccount
        \o message.legPositionEffect
        \o message.pad5

DecodeLegOrdGrpComp2(bytes) ==
    LET legAccount == ReadBytes(bytes, 2) IN IF ~legAccount.ok THEN Fail ELSE
    LET legPositionEffect == ReadBytes(legAccount.rest, 1) IN IF ~legPositionEffect.ok THEN Fail ELSE
    LET pad5 == ReadBytes(legPositionEffect.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ legAccount        |-> legAccount.value,
         legPositionEffect |-> legPositionEffect.value,
         pad5              |-> pad5.value ], pad5.rest)

ZeroLegOrdGrpComp2 ==
    [ legAccount        |-> [i \in 1 .. 2 |-> 0],
      legPositionEffect |-> [i \in 1 .. 1 |-> 0],
      pad5              |-> [i \in 1 .. 5 |-> 0] ]

(* Leg Ord Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedLegOrdGrpComp2 ==
    { ZeroLegOrdGrpComp2 }
        \cup { [ZeroLegOrdGrpComp2 EXCEPT !.legAccount = one] : one \in Sample(2) }
        \cup { [ZeroLegOrdGrpComp2 EXCEPT !.legPositionEffect = one] : one \in Sample(1) }
        \cup { [ZeroLegOrdGrpComp2 EXCEPT !.pad5 = one] : one \in Sample(5) }

(* A run of Leg Ord Grp Comp, written one after another *)
RECURSIVE EncodeLegOrdGrpComp2List(_)
EncodeLegOrdGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLegOrdGrpComp2(Head(messages)) \o EncodeLegOrdGrpComp2List(Tail(messages))

(* As many Leg Ord Grp Comp as the field that counts them says *)
RECURSIVE ReadLegOrdGrpComp2List(_, _)
ReadLegOrdGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLegOrdGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLegOrdGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Leg Ord Grp Comp of each kind, for the lists that carry them *)
OneLegOrdGrpComp2 == { ZeroLegOrdGrpComp2 }

(***************************************************************************)
(* New Order Complex Request                                               *)
(***************************************************************************)

NewOrderComplexRequest ==
    [ networkMsgId                : Sample(8),
      pad2                        : Sample(2),
      requestHeaderComp           : RequestHeaderComp15,
      clOrdId                     : Sample(8),
      securityId                  : Sample(8),
      maxPricePercentage          : Sample(8),
      senderLocationId            : Sample(8),
      price                       : Sample(8),
      filler1                     : Sample(8),
      filler2                     : Sample(4),
      messageTag                  : Sample(4),
      marketSegmentId             : Sample(4),
      orderQty                    : Sample(4),
      maxShow                     : Sample(4),
      expireDate                  : Sample(4),
      regulatoryId                : Sample(4),
      filler4                     : Sample(2),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      accountType                 : Sample(1),
      applSeqIndicator            : Sample(1),
      productComplex              : Sample(1),
      side                        : Sample(1),
      ordType                     : Sample(1),
      priceValidityCheckType      : Sample(1),
      execInst                    : Sample(1),
      timeInForce                 : Sample(1),
      stpcFlag                    : Sample(1),
      rolloverFlag                : Sample(1),
      tradingCapacity             : Sample(1),
      partyIdLocationId           : Sample(2),
      regulatoryText              : Sample(20),
      algoId                      : Sample(16),
      custOrderHandlingInst       : Sample(1),
      clientCode                  : Sample(12),
      cpCode                      : Sample(12),
      freeText3                   : Sample(12),
      pad6                        : Sample(6),
      legOrdGrpComp               : SampleLists(OneLegOrdGrpComp2) ]

EncodeNewOrderComplexRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp15(message.requestHeaderComp)
        \o message.clOrdId
        \o message.securityId
        \o message.maxPricePercentage
        \o message.senderLocationId
        \o message.price
        \o message.filler1
        \o message.filler2
        \o message.messageTag
        \o message.marketSegmentId
        \o message.orderQty
        \o message.maxShow
        \o message.expireDate
        \o message.regulatoryId
        \o message.filler4
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.accountType
        \o message.applSeqIndicator
        \o message.productComplex
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.execInst
        \o message.timeInForce
        \o message.stpcFlag
        \o message.rolloverFlag
        \o message.tradingCapacity
        \o message.partyIdLocationId
        \o message.regulatoryText
        \o message.algoId
        \o message.custOrderHandlingInst
        \o message.clientCode
        \o message.cpCode
        \o message.freeText3
        \o EncodeUIntBE(Len(message.legOrdGrpComp), 1)
        \o message.pad6
        \o EncodeLegOrdGrpComp2List(message.legOrdGrpComp)

DecodeNewOrderComplexRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp15(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET maxPricePercentage == ReadBytes(securityId.rest, 8) IN IF ~maxPricePercentage.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(maxPricePercentage.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET price == ReadBytes(senderLocationId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET filler1 == ReadBytes(price.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET messageTag == ReadBytes(filler2.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(messageTag.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET maxShow == ReadBytes(orderQty.rest, 4) IN IF ~maxShow.ok THEN Fail ELSE
    LET expireDate == ReadBytes(maxShow.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET regulatoryId == ReadBytes(expireDate.rest, 4) IN IF ~regulatoryId.ok THEN Fail ELSE
    LET filler4 == ReadBytes(regulatoryId.rest, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(filler4.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET accountType == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(accountType.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET productComplex == ReadBytes(applSeqIndicator.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET side == ReadBytes(productComplex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET execInst == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(execInst.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET stpcFlag == ReadBytes(timeInForce.rest, 1) IN IF ~stpcFlag.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(stpcFlag.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(rolloverFlag.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(tradingCapacity.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET regulatoryText == ReadBytes(partyIdLocationId.rest, 20) IN IF ~regulatoryText.ok THEN Fail ELSE
    LET algoId == ReadBytes(regulatoryText.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(algoId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET clientCode == ReadBytes(custOrderHandlingInst.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(cpCode.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(freeText3.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET pad6 == ReadBytes(noLegs.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    LET legOrdGrpComp == ReadLegOrdGrpComp2List(pad6.rest, noLegs.value) IN IF ~legOrdGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                |-> networkMsgId.value,
         pad2                        |-> pad2.value,
         requestHeaderComp           |-> requestHeaderComp.value,
         clOrdId                     |-> clOrdId.value,
         securityId                  |-> securityId.value,
         maxPricePercentage          |-> maxPricePercentage.value,
         senderLocationId            |-> senderLocationId.value,
         price                       |-> price.value,
         filler1                     |-> filler1.value,
         filler2                     |-> filler2.value,
         messageTag                  |-> messageTag.value,
         marketSegmentId             |-> marketSegmentId.value,
         orderQty                    |-> orderQty.value,
         maxShow                     |-> maxShow.value,
         expireDate                  |-> expireDate.value,
         regulatoryId                |-> regulatoryId.value,
         filler4                     |-> filler4.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         accountType                 |-> accountType.value,
         applSeqIndicator            |-> applSeqIndicator.value,
         productComplex              |-> productComplex.value,
         side                        |-> side.value,
         ordType                     |-> ordType.value,
         priceValidityCheckType      |-> priceValidityCheckType.value,
         execInst                    |-> execInst.value,
         timeInForce                 |-> timeInForce.value,
         stpcFlag                    |-> stpcFlag.value,
         rolloverFlag                |-> rolloverFlag.value,
         tradingCapacity             |-> tradingCapacity.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         regulatoryText              |-> regulatoryText.value,
         algoId                      |-> algoId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         clientCode                  |-> clientCode.value,
         cpCode                      |-> cpCode.value,
         freeText3                   |-> freeText3.value,
         pad6                        |-> pad6.value,
         legOrdGrpComp               |-> legOrdGrpComp.value ], legOrdGrpComp.rest)

ZeroNewOrderComplexRequest ==
    [ networkMsgId                |-> [i \in 1 .. 8 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp           |-> ZeroRequestHeaderComp15,
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      securityId                  |-> [i \in 1 .. 8 |-> 0],
      maxPricePercentage          |-> [i \in 1 .. 8 |-> 0],
      senderLocationId            |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      filler1                     |-> [i \in 1 .. 8 |-> 0],
      filler2                     |-> [i \in 1 .. 4 |-> 0],
      messageTag                  |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      maxShow                     |-> [i \in 1 .. 4 |-> 0],
      expireDate                  |-> [i \in 1 .. 4 |-> 0],
      regulatoryId                |-> [i \in 1 .. 4 |-> 0],
      filler4                     |-> [i \in 1 .. 2 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      accountType                 |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator            |-> [i \in 1 .. 1 |-> 0],
      productComplex              |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      ordType                     |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType      |-> [i \in 1 .. 1 |-> 0],
      execInst                    |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      stpcFlag                    |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag                |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      regulatoryText              |-> [i \in 1 .. 20 |-> 0],
      algoId                      |-> [i \in 1 .. 16 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      clientCode                  |-> [i \in 1 .. 12 |-> 0],
      cpCode                      |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      pad6                        |-> [i \in 1 .. 6 |-> 0],
      legOrdGrpComp               |-> << >> ]

(* New Order Complex Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderComplexRequest ==
    { ZeroNewOrderComplexRequest }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp15 }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.maxPricePercentage = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.maxShow = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.regulatoryId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.stpcFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.regulatoryText = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.pad6 = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.legOrdGrpComp = one] : one \in SampleLists(OneLegOrdGrpComp2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp16 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp16(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp16(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp16 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp16 ==
    { ZeroRequestHeaderComp16 }
        \cup { [ZeroRequestHeaderComp16 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp16 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* New Order Single Request: 210 bytes                                     *)
(***************************************************************************)

NewOrderSingleRequest ==
    [ networkMsgId                : Sample(8),
      pad2                        : Sample(2),
      requestHeaderComp           : RequestHeaderComp16,
      price                       : Sample(8),
      stopPx                      : Sample(8),
      maxPricePercentage          : Sample(8),
      senderLocationId            : Sample(8),
      clOrdId                     : Sample(8),
      filler1                     : Sample(8),
      filler2                     : Sample(4),
      messageTag                  : Sample(4),
      orderQty                    : Sample(4),
      maxShow                     : Sample(4),
      expireDate                  : Sample(4),
      marketSegmentId             : Sample(4),
      simpleSecurityId            : Sample(4),
      regulatoryId                : Sample(4),
      filler4                     : Sample(2),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      accountType                 : Sample(1),
      applSeqIndicator            : Sample(1),
      side                        : Sample(1),
      ordType                     : Sample(1),
      priceValidityCheckType      : Sample(1),
      timeInForce                 : Sample(1),
      execInst                    : Sample(1),
      stpcFlag                    : Sample(1),
      rolloverFlag                : Sample(1),
      tradingSessionSubId         : Sample(1),
      tradingCapacity             : Sample(1),
      account                     : Sample(2),
      positionEffect              : Sample(1),
      partyIdLocationId           : Sample(2),
      custOrderHandlingInst       : Sample(1),
      regulatoryText              : Sample(20),
      algoId                      : Sample(16),
      clientCode                  : Sample(12),
      cpCode                      : Sample(12),
      freeText3                   : Sample(12) ]

EncodeNewOrderSingleRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp16(message.requestHeaderComp)
        \o message.price
        \o message.stopPx
        \o message.maxPricePercentage
        \o message.senderLocationId
        \o message.clOrdId
        \o message.filler1
        \o message.filler2
        \o message.messageTag
        \o message.orderQty
        \o message.maxShow
        \o message.expireDate
        \o message.marketSegmentId
        \o message.simpleSecurityId
        \o message.regulatoryId
        \o message.filler4
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.accountType
        \o message.applSeqIndicator
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.timeInForce
        \o message.execInst
        \o message.stpcFlag
        \o message.rolloverFlag
        \o message.tradingSessionSubId
        \o message.tradingCapacity
        \o message.account
        \o message.positionEffect
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.regulatoryText
        \o message.algoId
        \o message.clientCode
        \o message.cpCode
        \o message.freeText3

DecodeNewOrderSingleRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp16(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET price == ReadBytes(requestHeaderComp.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET maxPricePercentage == ReadBytes(stopPx.rest, 8) IN IF ~maxPricePercentage.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(maxPricePercentage.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(senderLocationId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET filler1 == ReadBytes(clOrdId.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    LET filler2 == ReadBytes(filler1.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET messageTag == ReadBytes(filler2.rest, 4) IN IF ~messageTag.ok THEN Fail ELSE
    LET orderQty == ReadBytes(messageTag.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET maxShow == ReadBytes(orderQty.rest, 4) IN IF ~maxShow.ok THEN Fail ELSE
    LET expireDate == ReadBytes(maxShow.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(expireDate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(marketSegmentId.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET regulatoryId == ReadBytes(simpleSecurityId.rest, 4) IN IF ~regulatoryId.ok THEN Fail ELSE
    LET filler4 == ReadBytes(regulatoryId.rest, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(filler4.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET accountType == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(accountType.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(applSeqIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET stpcFlag == ReadBytes(execInst.rest, 1) IN IF ~stpcFlag.ok THEN Fail ELSE
    LET rolloverFlag == ReadBytes(stpcFlag.rest, 1) IN IF ~rolloverFlag.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(rolloverFlag.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET account == ReadBytes(tradingCapacity.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(account.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(positionEffect.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET regulatoryText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~regulatoryText.ok THEN Fail ELSE
    LET algoId == ReadBytes(regulatoryText.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(cpCode.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    Ok([ networkMsgId                |-> networkMsgId.value,
         pad2                        |-> pad2.value,
         requestHeaderComp           |-> requestHeaderComp.value,
         price                       |-> price.value,
         stopPx                      |-> stopPx.value,
         maxPricePercentage          |-> maxPricePercentage.value,
         senderLocationId            |-> senderLocationId.value,
         clOrdId                     |-> clOrdId.value,
         filler1                     |-> filler1.value,
         filler2                     |-> filler2.value,
         messageTag                  |-> messageTag.value,
         orderQty                    |-> orderQty.value,
         maxShow                     |-> maxShow.value,
         expireDate                  |-> expireDate.value,
         marketSegmentId             |-> marketSegmentId.value,
         simpleSecurityId            |-> simpleSecurityId.value,
         regulatoryId                |-> regulatoryId.value,
         filler4                     |-> filler4.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         accountType                 |-> accountType.value,
         applSeqIndicator            |-> applSeqIndicator.value,
         side                        |-> side.value,
         ordType                     |-> ordType.value,
         priceValidityCheckType      |-> priceValidityCheckType.value,
         timeInForce                 |-> timeInForce.value,
         execInst                    |-> execInst.value,
         stpcFlag                    |-> stpcFlag.value,
         rolloverFlag                |-> rolloverFlag.value,
         tradingSessionSubId         |-> tradingSessionSubId.value,
         tradingCapacity             |-> tradingCapacity.value,
         account                     |-> account.value,
         positionEffect              |-> positionEffect.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         regulatoryText              |-> regulatoryText.value,
         algoId                      |-> algoId.value,
         clientCode                  |-> clientCode.value,
         cpCode                      |-> cpCode.value,
         freeText3                   |-> freeText3.value ], freeText3.rest)

ZeroNewOrderSingleRequest ==
    [ networkMsgId                |-> [i \in 1 .. 8 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp           |-> ZeroRequestHeaderComp16,
      price                       |-> [i \in 1 .. 8 |-> 0],
      stopPx                      |-> [i \in 1 .. 8 |-> 0],
      maxPricePercentage          |-> [i \in 1 .. 8 |-> 0],
      senderLocationId            |-> [i \in 1 .. 8 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      filler1                     |-> [i \in 1 .. 8 |-> 0],
      filler2                     |-> [i \in 1 .. 4 |-> 0],
      messageTag                  |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      maxShow                     |-> [i \in 1 .. 4 |-> 0],
      expireDate                  |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId            |-> [i \in 1 .. 4 |-> 0],
      regulatoryId                |-> [i \in 1 .. 4 |-> 0],
      filler4                     |-> [i \in 1 .. 2 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      accountType                 |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator            |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      ordType                     |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType      |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      execInst                    |-> [i \in 1 .. 1 |-> 0],
      stpcFlag                    |-> [i \in 1 .. 1 |-> 0],
      rolloverFlag                |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId         |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      account                     |-> [i \in 1 .. 2 |-> 0],
      positionEffect              |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      regulatoryText              |-> [i \in 1 .. 20 |-> 0],
      algoId                      |-> [i \in 1 .. 16 |-> 0],
      clientCode                  |-> [i \in 1 .. 12 |-> 0],
      cpCode                      |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0] ]

(* New Order Single Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleRequest ==
    { ZeroNewOrderSingleRequest }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp16 }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.maxPricePercentage = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.filler1 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.messageTag = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.maxShow = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.regulatoryId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.stpcFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.rolloverFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.regulatoryText = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.cpCode = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp17 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp17(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp17(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp17 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp17 ==
    { ZeroRequestHeaderComp17 }
        \cup { [ZeroRequestHeaderComp17 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp17 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* New Order Single Short Request: 106 bytes                               *)
(***************************************************************************)

NewOrderSingleShortRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp17,
      price                  : Sample(8),
      senderLocationId       : Sample(8),
      clOrdId                : Sample(8),
      orderQty               : Sample(4),
      maxShow                : Sample(4),
      simpleSecurityId       : Sample(4),
      filler2                : Sample(4),
      filler4                : Sample(2),
      accountType            : Sample(1),
      side                   : Sample(1),
      priceValidityCheckType : Sample(1),
      timeInForce            : Sample(1),
      stpcFlag               : Sample(1),
      execInst               : Sample(1),
      algoId                 : Sample(16),
      clientCode             : Sample(12),
      cpCode                 : Sample(12) ]

EncodeNewOrderSingleShortRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp17(message.requestHeaderComp)
        \o message.price
        \o message.senderLocationId
        \o message.clOrdId
        \o message.orderQty
        \o message.maxShow
        \o message.simpleSecurityId
        \o message.filler2
        \o message.filler4
        \o message.accountType
        \o message.side
        \o message.priceValidityCheckType
        \o message.timeInForce
        \o message.stpcFlag
        \o message.execInst
        \o message.algoId
        \o message.clientCode
        \o message.cpCode

DecodeNewOrderSingleShortRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp17(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET price == ReadBytes(requestHeaderComp.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET senderLocationId == ReadBytes(price.rest, 8) IN IF ~senderLocationId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(senderLocationId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clOrdId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET maxShow == ReadBytes(orderQty.rest, 4) IN IF ~maxShow.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(maxShow.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET filler2 == ReadBytes(simpleSecurityId.rest, 4) IN IF ~filler2.ok THEN Fail ELSE
    LET filler4 == ReadBytes(filler2.rest, 2) IN IF ~filler4.ok THEN Fail ELSE
    LET accountType == ReadBytes(filler4.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET side == ReadBytes(accountType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(side.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET stpcFlag == ReadBytes(timeInForce.rest, 1) IN IF ~stpcFlag.ok THEN Fail ELSE
    LET execInst == ReadBytes(stpcFlag.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET algoId == ReadBytes(execInst.rest, 16) IN IF ~algoId.ok THEN Fail ELSE
    LET clientCode == ReadBytes(algoId.rest, 12) IN IF ~clientCode.ok THEN Fail ELSE
    LET cpCode == ReadBytes(clientCode.rest, 12) IN IF ~cpCode.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         price                  |-> price.value,
         senderLocationId       |-> senderLocationId.value,
         clOrdId                |-> clOrdId.value,
         orderQty               |-> orderQty.value,
         maxShow                |-> maxShow.value,
         simpleSecurityId       |-> simpleSecurityId.value,
         filler2                |-> filler2.value,
         filler4                |-> filler4.value,
         accountType            |-> accountType.value,
         side                   |-> side.value,
         priceValidityCheckType |-> priceValidityCheckType.value,
         timeInForce            |-> timeInForce.value,
         stpcFlag               |-> stpcFlag.value,
         execInst               |-> execInst.value,
         algoId                 |-> algoId.value,
         clientCode             |-> clientCode.value,
         cpCode                 |-> cpCode.value ], cpCode.rest)

ZeroNewOrderSingleShortRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp17,
      price                  |-> [i \in 1 .. 8 |-> 0],
      senderLocationId       |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      maxShow                |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId       |-> [i \in 1 .. 4 |-> 0],
      filler2                |-> [i \in 1 .. 4 |-> 0],
      filler4                |-> [i \in 1 .. 2 |-> 0],
      accountType            |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType |-> [i \in 1 .. 1 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      stpcFlag               |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      algoId                 |-> [i \in 1 .. 16 |-> 0],
      clientCode             |-> [i \in 1 .. 12 |-> 0],
      cpCode                 |-> [i \in 1 .. 12 |-> 0] ]

(* New Order Single Short Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleShortRequest ==
    { ZeroNewOrderSingleShortRequest }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp17 }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.senderLocationId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.maxShow = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.filler2 = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.filler4 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.stpcFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.algoId = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.clientCode = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.cpCode = one] : one \in Sample(12) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp18 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp18(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp18(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp18 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp18 ==
    { ZeroRequestHeaderComp18 }
        \cup { [ZeroRequestHeaderComp18 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp18 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Me Message Request: 58 bytes                                 *)
(***************************************************************************)

RetransmitMeMessageRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp18,
      subscriptionScope : Sample(4),
      partitionId       : Sample(2),
      refApplId         : Sample(1),
      applBegMsgId      : Sample(16),
      applEndMsgId      : Sample(16),
      pad1              : Sample(1) ]

EncodeRetransmitMeMessageRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp18(message.requestHeaderComp)
        \o message.subscriptionScope
        \o message.partitionId
        \o message.refApplId
        \o message.applBegMsgId
        \o message.applEndMsgId
        \o message.pad1

DecodeRetransmitMeMessageRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp18(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET subscriptionScope == ReadBytes(requestHeaderComp.rest, 4) IN IF ~subscriptionScope.ok THEN Fail ELSE
    LET partitionId == ReadBytes(subscriptionScope.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET refApplId == ReadBytes(partitionId.rest, 1) IN IF ~refApplId.ok THEN Fail ELSE
    LET applBegMsgId == ReadBytes(refApplId.rest, 16) IN IF ~applBegMsgId.ok THEN Fail ELSE
    LET applEndMsgId == ReadBytes(applBegMsgId.rest, 16) IN IF ~applEndMsgId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(applEndMsgId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         subscriptionScope |-> subscriptionScope.value,
         partitionId       |-> partitionId.value,
         refApplId         |-> refApplId.value,
         applBegMsgId      |-> applBegMsgId.value,
         applEndMsgId      |-> applEndMsgId.value,
         pad1              |-> pad1.value ], pad1.rest)

ZeroRetransmitMeMessageRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp18,
      subscriptionScope |-> [i \in 1 .. 4 |-> 0],
      partitionId       |-> [i \in 1 .. 2 |-> 0],
      refApplId         |-> [i \in 1 .. 1 |-> 0],
      applBegMsgId      |-> [i \in 1 .. 16 |-> 0],
      applEndMsgId      |-> [i \in 1 .. 16 |-> 0],
      pad1              |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmit Me Message Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitMeMessageRequest ==
    { ZeroRetransmitMeMessageRequest }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp18 }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.subscriptionScope = one] : one \in Sample(4) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.applBegMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.applEndMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp19 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp19(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp19(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp19 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp19 ==
    { ZeroRequestHeaderComp19 }
        \cup { [ZeroRequestHeaderComp19 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp19 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Request: 42 bytes                                            *)
(***************************************************************************)

RetransmitRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp19,
      applBegSeqNum     : Sample(8),
      applEndSeqNum     : Sample(8),
      subscriptionScope : Sample(4),
      partitionId       : Sample(2),
      refApplId         : Sample(1),
      pad1              : Sample(1) ]

EncodeRetransmitRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp19(message.requestHeaderComp)
        \o message.applBegSeqNum
        \o message.applEndSeqNum
        \o message.subscriptionScope
        \o message.partitionId
        \o message.refApplId
        \o message.pad1

DecodeRetransmitRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp19(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET applBegSeqNum == ReadBytes(requestHeaderComp.rest, 8) IN IF ~applBegSeqNum.ok THEN Fail ELSE
    LET applEndSeqNum == ReadBytes(applBegSeqNum.rest, 8) IN IF ~applEndSeqNum.ok THEN Fail ELSE
    LET subscriptionScope == ReadBytes(applEndSeqNum.rest, 4) IN IF ~subscriptionScope.ok THEN Fail ELSE
    LET partitionId == ReadBytes(subscriptionScope.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET refApplId == ReadBytes(partitionId.rest, 1) IN IF ~refApplId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(refApplId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         applBegSeqNum     |-> applBegSeqNum.value,
         applEndSeqNum     |-> applEndSeqNum.value,
         subscriptionScope |-> subscriptionScope.value,
         partitionId       |-> partitionId.value,
         refApplId         |-> refApplId.value,
         pad1              |-> pad1.value ], pad1.rest)

ZeroRetransmitRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp19,
      applBegSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applEndSeqNum     |-> [i \in 1 .. 8 |-> 0],
      subscriptionScope |-> [i \in 1 .. 4 |-> 0],
      partitionId       |-> [i \in 1 .. 2 |-> 0],
      refApplId         |-> [i \in 1 .. 1 |-> 0],
      pad1              |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmit Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRequest ==
    { ZeroRetransmitRequest }
        \cup { [ZeroRetransmitRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp19 }
        \cup { [ZeroRetransmitRequest EXCEPT !.applBegSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.applEndSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.subscriptionScope = one] : one \in Sample(4) }
        \cup { [ZeroRetransmitRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroRetransmitRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp20 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp20(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp20(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp20 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp20 ==
    { ZeroRequestHeaderComp20 }
        \cup { [ZeroRequestHeaderComp20 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp20 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Session Password Change Request: 90 bytes                               *)
(***************************************************************************)

SessionPasswordChangeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp20,
      partyIdSessionId  : Sample(4),
      password          : Sample(32),
      newPassword       : Sample(32),
      pad4              : Sample(4) ]

EncodeSessionPasswordChangeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp20(message.requestHeaderComp)
        \o message.partyIdSessionId
        \o message.password
        \o message.newPassword
        \o message.pad4

DecodeSessionPasswordChangeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp20(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET password == ReadBytes(partyIdSessionId.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET newPassword == ReadBytes(password.rest, 32) IN IF ~newPassword.ok THEN Fail ELSE
    LET pad4 == ReadBytes(newPassword.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         partyIdSessionId  |-> partyIdSessionId.value,
         password          |-> password.value,
         newPassword       |-> newPassword.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroSessionPasswordChangeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp20,
      partyIdSessionId  |-> [i \in 1 .. 4 |-> 0],
      password          |-> [i \in 1 .. 32 |-> 0],
      newPassword       |-> [i \in 1 .. 32 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Session Password Change Request at zero, then each field in turn at the values it is checked at *)
CheckedSessionPasswordChangeRequest ==
    { ZeroSessionPasswordChangeRequest }
        \cup { [ZeroSessionPasswordChangeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSessionPasswordChangeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSessionPasswordChangeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp20 }
        \cup { [ZeroSessionPasswordChangeRequest EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroSessionPasswordChangeRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroSessionPasswordChangeRequest EXCEPT !.newPassword = one] : one \in Sample(32) }
        \cup { [ZeroSessionPasswordChangeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp21 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp21(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp21(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp21 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp21 ==
    { ZeroRequestHeaderComp21 }
        \cup { [ZeroRequestHeaderComp21 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp21 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Session Registration Request: 34 bytes                                  *)
(***************************************************************************)

SessionRegistrationRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp21,
      partyIdSessionId  : Sample(4),
      pad4              : Sample(4),
      filler1           : Sample(8) ]

EncodeSessionRegistrationRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp21(message.requestHeaderComp)
        \o message.partyIdSessionId
        \o message.pad4
        \o message.filler1

DecodeSessionRegistrationRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp21(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partyIdSessionId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~partyIdSessionId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyIdSessionId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET filler1 == ReadBytes(pad4.rest, 8) IN IF ~filler1.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         partyIdSessionId  |-> partyIdSessionId.value,
         pad4              |-> pad4.value,
         filler1           |-> filler1.value ], filler1.rest)

ZeroSessionRegistrationRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp21,
      partyIdSessionId  |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0],
      filler1           |-> [i \in 1 .. 8 |-> 0] ]

(* Session Registration Request at zero, then each field in turn at the values it is checked at *)
CheckedSessionRegistrationRequest ==
    { ZeroSessionRegistrationRequest }
        \cup { [ZeroSessionRegistrationRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSessionRegistrationRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSessionRegistrationRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp21 }
        \cup { [ZeroSessionRegistrationRequest EXCEPT !.partyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroSessionRegistrationRequest EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroSessionRegistrationRequest EXCEPT !.filler1 = one] : one \in Sample(8) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp22 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp22(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp22(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp22 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp22 ==
    { ZeroRequestHeaderComp22 }
        \cup { [ZeroRequestHeaderComp22 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp22 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Subscribe Request: 26 bytes                                             *)
(***************************************************************************)

SubscribeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp22,
      subscriptionScope : Sample(4),
      refApplId         : Sample(1),
      pad3              : Sample(3) ]

EncodeSubscribeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp22(message.requestHeaderComp)
        \o message.subscriptionScope
        \o message.refApplId
        \o message.pad3

DecodeSubscribeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp22(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET subscriptionScope == ReadBytes(requestHeaderComp.rest, 4) IN IF ~subscriptionScope.ok THEN Fail ELSE
    LET refApplId == ReadBytes(subscriptionScope.rest, 1) IN IF ~refApplId.ok THEN Fail ELSE
    LET pad3 == ReadBytes(refApplId.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         subscriptionScope |-> subscriptionScope.value,
         refApplId         |-> refApplId.value,
         pad3              |-> pad3.value ], pad3.rest)

ZeroSubscribeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp22,
      subscriptionScope |-> [i \in 1 .. 4 |-> 0],
      refApplId         |-> [i \in 1 .. 1 |-> 0],
      pad3              |-> [i \in 1 .. 3 |-> 0] ]

(* Subscribe Request at zero, then each field in turn at the values it is checked at *)
CheckedSubscribeRequest ==
    { ZeroSubscribeRequest }
        \cup { [ZeroSubscribeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSubscribeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSubscribeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp22 }
        \cup { [ZeroSubscribeRequest EXCEPT !.subscriptionScope = one] : one \in Sample(4) }
        \cup { [ZeroSubscribeRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroSubscribeRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp23 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp23(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp23(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp23 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp23 ==
    { ZeroRequestHeaderComp23 }
        \cup { [ZeroRequestHeaderComp23 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp23 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Unsubscribe Request: 26 bytes                                           *)
(***************************************************************************)

UnsubscribeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp23,
      refApplSubId      : Sample(4),
      pad4              : Sample(4) ]

EncodeUnsubscribeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp23(message.requestHeaderComp)
        \o message.refApplSubId
        \o message.pad4

DecodeUnsubscribeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp23(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET refApplSubId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~refApplSubId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(refApplSubId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         refApplSubId      |-> refApplSubId.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroUnsubscribeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp23,
      refApplSubId      |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Unsubscribe Request at zero, then each field in turn at the values it is checked at *)
CheckedUnsubscribeRequest ==
    { ZeroUnsubscribeRequest }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp23 }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.refApplSubId = one] : one \in Sample(4) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp24 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp24(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp24(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp24 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp24 ==
    { ZeroRequestHeaderComp24 }
        \cup { [ZeroRequestHeaderComp24 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp24 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* User Login Request: 58 bytes                                            *)
(***************************************************************************)

UserLoginRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp24,
      username          : Sample(4),
      password          : Sample(32),
      pad4              : Sample(4) ]

EncodeUserLoginRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp24(message.requestHeaderComp)
        \o message.username
        \o message.password
        \o message.pad4

DecodeUserLoginRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp24(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET username == ReadBytes(requestHeaderComp.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET pad4 == ReadBytes(password.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         username          |-> username.value,
         password          |-> password.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroUserLoginRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp24,
      username          |-> [i \in 1 .. 4 |-> 0],
      password          |-> [i \in 1 .. 32 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* User Login Request at zero, then each field in turn at the values it is checked at *)
CheckedUserLoginRequest ==
    { ZeroUserLoginRequest }
        \cup { [ZeroUserLoginRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserLoginRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLoginRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp24 }
        \cup { [ZeroUserLoginRequest EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserLoginRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroUserLoginRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp25 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp25(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp25(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp25 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp25 ==
    { ZeroRequestHeaderComp25 }
        \cup { [ZeroRequestHeaderComp25 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp25 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* User Logout Request: 26 bytes                                           *)
(***************************************************************************)

UserLogoutRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp25,
      username          : Sample(4),
      pad4              : Sample(4) ]

EncodeUserLogoutRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp25(message.requestHeaderComp)
        \o message.username
        \o message.pad4

DecodeUserLogoutRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp25(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET username == ReadBytes(requestHeaderComp.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET pad4 == ReadBytes(username.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         username          |-> username.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroUserLogoutRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp25,
      username          |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* User Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedUserLogoutRequest ==
    { ZeroUserLogoutRequest }
        \cup { [ZeroUserLogoutRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp25 }
        \cup { [ZeroUserLogoutRequest EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp26 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp26(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp26(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp26 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp26 ==
    { ZeroRequestHeaderComp26 }
        \cup { [ZeroRequestHeaderComp26 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp26 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* User Password Change Request: 90 bytes                                  *)
(***************************************************************************)

UserPasswordChangeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp26,
      username          : Sample(4),
      password          : Sample(32),
      newPassword       : Sample(32),
      pad4              : Sample(4) ]

EncodeUserPasswordChangeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp26(message.requestHeaderComp)
        \o message.username
        \o message.password
        \o message.newPassword
        \o message.pad4

DecodeUserPasswordChangeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp26(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET username == ReadBytes(requestHeaderComp.rest, 4) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 32) IN IF ~password.ok THEN Fail ELSE
    LET newPassword == ReadBytes(password.rest, 32) IN IF ~newPassword.ok THEN Fail ELSE
    LET pad4 == ReadBytes(newPassword.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         username          |-> username.value,
         password          |-> password.value,
         newPassword       |-> newPassword.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroUserPasswordChangeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp26,
      username          |-> [i \in 1 .. 4 |-> 0],
      password          |-> [i \in 1 .. 32 |-> 0],
      newPassword       |-> [i \in 1 .. 32 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* User Password Change Request at zero, then each field in turn at the values it is checked at *)
CheckedUserPasswordChangeRequest ==
    { ZeroUserPasswordChangeRequest }
        \cup { [ZeroUserPasswordChangeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserPasswordChangeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserPasswordChangeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp26 }
        \cup { [ZeroUserPasswordChangeRequest EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserPasswordChangeRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroUserPasswordChangeRequest EXCEPT !.newPassword = one] : one \in Sample(32) }
        \cup { [ZeroUserPasswordChangeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

DebtInquiryRequestCode == 10390  \* 0x2896
DeleteAllOrderRequestCode == 10120  \* 0x2788
DeleteAllQuoteRequestCode == 10408  \* 0x28a8
DeleteOrderComplexRequestCode == 10123  \* 0x278b
DeleteOrderSingleRequestCode == 10109  \* 0x277d
GatewayRequestCode == 10020  \* 0x2724
HeartbeatCode == 10011  \* 0x271b
InquireSessionListRequestCode == 10035  \* 0x2733
LogonRequestCode == 10000  \* 0x2710
LogoutRequestCode == 10002  \* 0x2712
MassQuoteRequestCode == 10405  \* 0x28a5
ModifyOrderComplexRequestCode == 10114  \* 0x2782
ModifyOrderSingleRequestCode == 10106  \* 0x277a
ModifyOrderSingleShortRequestCode == 10126  \* 0x278e
MultiLegOrderRequestCode == 10991  \* 0x2aef
NewOrderComplexRequestCode == 10113  \* 0x2781
NewOrderSingleRequestCode == 10100  \* 0x2774
NewOrderSingleShortRequestCode == 10125  \* 0x278d
RetransmitMeMessageRequestCode == 10026  \* 0x272a
RetransmitRequestCode == 10008  \* 0x2718
SessionPasswordChangeRequestCode == 10997  \* 0x2af5
SessionRegistrationRequestCode == 10053  \* 0x2745
SubscribeRequestCode == 10025  \* 0x2729
UnsubscribeRequestCode == 10006  \* 0x2716
UserLoginRequestCode == 10018  \* 0x2722
UserLogoutRequestCode == 10029  \* 0x272d
UserPasswordChangeRequestCode == 10996  \* 0x2af4

ClientPayload ==
    [ tag : {DebtInquiryRequestCode}, body : DebtInquiryRequest ]
        \cup [ tag : {DeleteAllOrderRequestCode}, body : DeleteAllOrderRequest ]
        \cup [ tag : {DeleteAllQuoteRequestCode}, body : DeleteAllQuoteRequest ]
        \cup [ tag : {DeleteOrderComplexRequestCode}, body : DeleteOrderComplexRequest ]
        \cup [ tag : {DeleteOrderSingleRequestCode}, body : DeleteOrderSingleRequest ]
        \cup [ tag : {GatewayRequestCode}, body : GatewayRequest ]
        \cup [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {InquireSessionListRequestCode}, body : InquireSessionListRequest ]
        \cup [ tag : {LogonRequestCode}, body : LogonRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {MassQuoteRequestCode}, body : MassQuoteRequest ]
        \cup [ tag : {ModifyOrderComplexRequestCode}, body : ModifyOrderComplexRequest ]
        \cup [ tag : {ModifyOrderSingleRequestCode}, body : ModifyOrderSingleRequest ]
        \cup [ tag : {ModifyOrderSingleShortRequestCode}, body : ModifyOrderSingleShortRequest ]
        \cup [ tag : {MultiLegOrderRequestCode}, body : MultiLegOrderRequest ]
        \cup [ tag : {NewOrderComplexRequestCode}, body : NewOrderComplexRequest ]
        \cup [ tag : {NewOrderSingleRequestCode}, body : NewOrderSingleRequest ]
        \cup [ tag : {NewOrderSingleShortRequestCode}, body : NewOrderSingleShortRequest ]
        \cup [ tag : {RetransmitMeMessageRequestCode}, body : RetransmitMeMessageRequest ]
        \cup [ tag : {RetransmitRequestCode}, body : RetransmitRequest ]
        \cup [ tag : {SessionPasswordChangeRequestCode}, body : SessionPasswordChangeRequest ]
        \cup [ tag : {SessionRegistrationRequestCode}, body : SessionRegistrationRequest ]
        \cup [ tag : {SubscribeRequestCode}, body : SubscribeRequest ]
        \cup [ tag : {UnsubscribeRequestCode}, body : UnsubscribeRequest ]
        \cup [ tag : {UserLoginRequestCode}, body : UserLoginRequest ]
        \cup [ tag : {UserLogoutRequestCode}, body : UserLogoutRequest ]
        \cup [ tag : {UserPasswordChangeRequestCode}, body : UserPasswordChangeRequest ]

EncodeClientPayload(message) ==
    CASE message.tag = DebtInquiryRequestCode -> EncodeDebtInquiryRequest(message.body)
      [] message.tag = DeleteAllOrderRequestCode -> EncodeDeleteAllOrderRequest(message.body)
      [] message.tag = DeleteAllQuoteRequestCode -> EncodeDeleteAllQuoteRequest(message.body)
      [] message.tag = DeleteOrderComplexRequestCode -> EncodeDeleteOrderComplexRequest(message.body)
      [] message.tag = DeleteOrderSingleRequestCode -> EncodeDeleteOrderSingleRequest(message.body)
      [] message.tag = GatewayRequestCode -> EncodeGatewayRequest(message.body)
      [] message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = InquireSessionListRequestCode -> EncodeInquireSessionListRequest(message.body)
      [] message.tag = LogonRequestCode -> EncodeLogonRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = MassQuoteRequestCode -> EncodeMassQuoteRequest(message.body)
      [] message.tag = ModifyOrderComplexRequestCode -> EncodeModifyOrderComplexRequest(message.body)
      [] message.tag = ModifyOrderSingleRequestCode -> EncodeModifyOrderSingleRequest(message.body)
      [] message.tag = ModifyOrderSingleShortRequestCode -> EncodeModifyOrderSingleShortRequest(message.body)
      [] message.tag = MultiLegOrderRequestCode -> EncodeMultiLegOrderRequest(message.body)
      [] message.tag = NewOrderComplexRequestCode -> EncodeNewOrderComplexRequest(message.body)
      [] message.tag = NewOrderSingleRequestCode -> EncodeNewOrderSingleRequest(message.body)
      [] message.tag = NewOrderSingleShortRequestCode -> EncodeNewOrderSingleShortRequest(message.body)
      [] message.tag = RetransmitMeMessageRequestCode -> EncodeRetransmitMeMessageRequest(message.body)
      [] message.tag = RetransmitRequestCode -> EncodeRetransmitRequest(message.body)
      [] message.tag = SessionPasswordChangeRequestCode -> EncodeSessionPasswordChangeRequest(message.body)
      [] message.tag = SessionRegistrationRequestCode -> EncodeSessionRegistrationRequest(message.body)
      [] message.tag = SubscribeRequestCode -> EncodeSubscribeRequest(message.body)
      [] message.tag = UnsubscribeRequestCode -> EncodeUnsubscribeRequest(message.body)
      [] message.tag = UserLoginRequestCode -> EncodeUserLoginRequest(message.body)
      [] message.tag = UserLogoutRequestCode -> EncodeUserLogoutRequest(message.body)
      [] message.tag = UserPasswordChangeRequestCode -> EncodeUserPasswordChangeRequest(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebtInquiryRequestCode -> DecodeDebtInquiryRequest(bytes)
              [] tag = DeleteAllOrderRequestCode -> DecodeDeleteAllOrderRequest(bytes)
              [] tag = DeleteAllQuoteRequestCode -> DecodeDeleteAllQuoteRequest(bytes)
              [] tag = DeleteOrderComplexRequestCode -> DecodeDeleteOrderComplexRequest(bytes)
              [] tag = DeleteOrderSingleRequestCode -> DecodeDeleteOrderSingleRequest(bytes)
              [] tag = GatewayRequestCode -> DecodeGatewayRequest(bytes)
              [] tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = InquireSessionListRequestCode -> DecodeInquireSessionListRequest(bytes)
              [] tag = LogonRequestCode -> DecodeLogonRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = MassQuoteRequestCode -> DecodeMassQuoteRequest(bytes)
              [] tag = ModifyOrderComplexRequestCode -> DecodeModifyOrderComplexRequest(bytes)
              [] tag = ModifyOrderSingleRequestCode -> DecodeModifyOrderSingleRequest(bytes)
              [] tag = ModifyOrderSingleShortRequestCode -> DecodeModifyOrderSingleShortRequest(bytes)
              [] tag = MultiLegOrderRequestCode -> DecodeMultiLegOrderRequest(bytes)
              [] tag = NewOrderComplexRequestCode -> DecodeNewOrderComplexRequest(bytes)
              [] tag = NewOrderSingleRequestCode -> DecodeNewOrderSingleRequest(bytes)
              [] tag = NewOrderSingleShortRequestCode -> DecodeNewOrderSingleShortRequest(bytes)
              [] tag = RetransmitMeMessageRequestCode -> DecodeRetransmitMeMessageRequest(bytes)
              [] tag = RetransmitRequestCode -> DecodeRetransmitRequest(bytes)
              [] tag = SessionPasswordChangeRequestCode -> DecodeSessionPasswordChangeRequest(bytes)
              [] tag = SessionRegistrationRequestCode -> DecodeSessionRegistrationRequest(bytes)
              [] tag = SubscribeRequestCode -> DecodeSubscribeRequest(bytes)
              [] tag = UnsubscribeRequestCode -> DecodeUnsubscribeRequest(bytes)
              [] tag = UserLoginRequestCode -> DecodeUserLoginRequest(bytes)
              [] tag = UserLogoutRequestCode -> DecodeUserLogoutRequest(bytes)
              [] tag = UserPasswordChangeRequestCode -> DecodeUserPasswordChangeRequest(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> DebtInquiryRequestCode, body |-> ZeroDebtInquiryRequest]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> DebtInquiryRequestCode, body |-> one] : one \in CheckedDebtInquiryRequest }
        \cup { [tag |-> DeleteAllOrderRequestCode, body |-> one] : one \in CheckedDeleteAllOrderRequest }
        \cup { [tag |-> DeleteAllQuoteRequestCode, body |-> one] : one \in CheckedDeleteAllQuoteRequest }
        \cup { [tag |-> DeleteOrderComplexRequestCode, body |-> one] : one \in CheckedDeleteOrderComplexRequest }
        \cup { [tag |-> DeleteOrderSingleRequestCode, body |-> one] : one \in CheckedDeleteOrderSingleRequest }
        \cup { [tag |-> GatewayRequestCode, body |-> one] : one \in CheckedGatewayRequest }
        \cup { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> InquireSessionListRequestCode, body |-> one] : one \in CheckedInquireSessionListRequest }
        \cup { [tag |-> LogonRequestCode, body |-> one] : one \in CheckedLogonRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> MassQuoteRequestCode, body |-> one] : one \in CheckedMassQuoteRequest }
        \cup { [tag |-> ModifyOrderComplexRequestCode, body |-> one] : one \in CheckedModifyOrderComplexRequest }
        \cup { [tag |-> ModifyOrderSingleRequestCode, body |-> one] : one \in CheckedModifyOrderSingleRequest }
        \cup { [tag |-> ModifyOrderSingleShortRequestCode, body |-> one] : one \in CheckedModifyOrderSingleShortRequest }
        \cup { [tag |-> MultiLegOrderRequestCode, body |-> one] : one \in CheckedMultiLegOrderRequest }
        \cup { [tag |-> NewOrderComplexRequestCode, body |-> one] : one \in CheckedNewOrderComplexRequest }
        \cup { [tag |-> NewOrderSingleRequestCode, body |-> one] : one \in CheckedNewOrderSingleRequest }
        \cup { [tag |-> NewOrderSingleShortRequestCode, body |-> one] : one \in CheckedNewOrderSingleShortRequest }
        \cup { [tag |-> RetransmitMeMessageRequestCode, body |-> one] : one \in CheckedRetransmitMeMessageRequest }
        \cup { [tag |-> RetransmitRequestCode, body |-> one] : one \in CheckedRetransmitRequest }
        \cup { [tag |-> SessionPasswordChangeRequestCode, body |-> one] : one \in CheckedSessionPasswordChangeRequest }
        \cup { [tag |-> SessionRegistrationRequestCode, body |-> one] : one \in CheckedSessionRegistrationRequest }
        \cup { [tag |-> SubscribeRequestCode, body |-> one] : one \in CheckedSubscribeRequest }
        \cup { [tag |-> UnsubscribeRequestCode, body |-> one] : one \in CheckedUnsubscribeRequest }
        \cup { [tag |-> UserLoginRequestCode, body |-> one] : one \in CheckedUserLoginRequest }
        \cup { [tag |-> UserLogoutRequestCode, body |-> one] : one \in CheckedUserLogoutRequest }
        \cup { [tag |-> UserPasswordChangeRequestCode, body |-> one] : one \in CheckedUserPasswordChangeRequest }

(***************************************************************************)
(* Client Message, framed by Body Len                                      *)
(***************************************************************************)

ClientMessage ==
    [ clientPayload : ClientPayload ]

EncodeClientMessageBody(message) ==
    EncodeUIntLE(message.clientPayload.tag, 2)
        \o EncodeClientPayload(message.clientPayload)

(* Body Len counts the bytes it frames, so it is written from them *)
EncodeClientMessage(message) ==
    LET body == EncodeClientMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 4, 4) \o body

DecodeClientMessageBody(bytes) ==
    LET templateId == ReadUIntLE(bytes, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, templateId.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 4) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientMessage ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Message at zero, then each field in turn at the values it is checked at *)
CheckedClientMessage ==
    { ZeroClientMessage }
        \cup { [ZeroClientMessage EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Message, written one after another *)
RECURSIVE EncodeClientMessageList(_)
EncodeClientMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientMessage(Head(messages)) \o EncodeClientMessageList(Tail(messages))

(* As many Client Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientMessageAll(_)
ReadClientMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Message of each kind, for the lists that carry them *)
OneClientMessage ==
    { [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DebtInquiryRequestCode, body |-> ZeroDebtInquiryRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteAllOrderRequestCode, body |-> ZeroDeleteAllOrderRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteAllQuoteRequestCode, body |-> ZeroDeleteAllQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteOrderComplexRequestCode, body |-> ZeroDeleteOrderComplexRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteOrderSingleRequestCode, body |-> ZeroDeleteOrderSingleRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> GatewayRequestCode, body |-> ZeroGatewayRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> HeartbeatCode, body |-> ZeroHeartbeat]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireSessionListRequestCode, body |-> ZeroInquireSessionListRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogonRequestCode, body |-> ZeroLogonRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> MassQuoteRequestCode, body |-> ZeroMassQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderComplexRequestCode, body |-> ZeroModifyOrderComplexRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderSingleRequestCode, body |-> ZeroModifyOrderSingleRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderSingleShortRequestCode, body |-> ZeroModifyOrderSingleShortRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> MultiLegOrderRequestCode, body |-> ZeroMultiLegOrderRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderComplexRequestCode, body |-> ZeroNewOrderComplexRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderSingleRequestCode, body |-> ZeroNewOrderSingleRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderSingleShortRequestCode, body |-> ZeroNewOrderSingleShortRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmitMeMessageRequestCode, body |-> ZeroRetransmitMeMessageRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmitRequestCode, body |-> ZeroRetransmitRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SessionPasswordChangeRequestCode, body |-> ZeroSessionPasswordChangeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SessionRegistrationRequestCode, body |-> ZeroSessionRegistrationRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SubscribeRequestCode, body |-> ZeroSubscribeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UnsubscribeRequestCode, body |-> ZeroUnsubscribeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserLoginRequestCode, body |-> ZeroUserLoginRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserLogoutRequestCode, body |-> ZeroUserLogoutRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserPasswordChangeRequestCode, body |-> ZeroUserPasswordChangeRequest]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientMessage : SampleLists(OneClientMessage) ]

EncodeClientPacket(message) ==
    EncodeClientMessageList(message.clientMessage)

DecodeClientPacket(bytes) ==
    LET clientMessage == ReadClientMessageAll(bytes) IN IF ~clientMessage.ok THEN Fail ELSE
    Ok([ clientMessage |-> clientMessage.value ], clientMessage.rest)

ZeroClientPacket ==
    [ clientMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientMessage = one] : one \in SampleLists(OneClientMessage) }

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

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp ==
    \A message \in CheckedRequestHeaderComp :
        LET read == DecodeRequestHeaderComp(EncodeRequestHeaderComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Debt Inquiry Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDebtInquiryRequest ==
    \A message \in CheckedDebtInquiryRequest :
        LET read == DecodeDebtInquiryRequest(EncodeDebtInquiryRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp2 ==
    \A message \in CheckedRequestHeaderComp2 :
        LET read == DecodeRequestHeaderComp2(EncodeRequestHeaderComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllOrderRequest ==
    \A message \in CheckedDeleteAllOrderRequest :
        LET read == DecodeDeleteAllOrderRequest(EncodeDeleteAllOrderRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp3 ==
    \A message \in CheckedRequestHeaderComp3 :
        LET read == DecodeRequestHeaderComp3(EncodeRequestHeaderComp3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete All Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllQuoteRequest ==
    \A message \in CheckedDeleteAllQuoteRequest :
        LET read == DecodeDeleteAllQuoteRequest(EncodeDeleteAllQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp4 ==
    \A message \in CheckedRequestHeaderComp4 :
        LET read == DecodeRequestHeaderComp4(EncodeRequestHeaderComp4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Complex Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderComplexRequest ==
    \A message \in CheckedDeleteOrderComplexRequest :
        LET read == DecodeDeleteOrderComplexRequest(EncodeDeleteOrderComplexRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp5 ==
    \A message \in CheckedRequestHeaderComp5 :
        LET read == DecodeRequestHeaderComp5(EncodeRequestHeaderComp5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Single Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderSingleRequest ==
    \A message \in CheckedDeleteOrderSingleRequest :
        LET read == DecodeDeleteOrderSingleRequest(EncodeDeleteOrderSingleRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp6 ==
    \A message \in CheckedRequestHeaderComp6 :
        LET read == DecodeRequestHeaderComp6(EncodeRequestHeaderComp6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gateway Request decodes back to what was encoded, and leaves nothing over *)
RoundTripGatewayRequest ==
    \A message \in CheckedGatewayRequest :
        LET read == DecodeGatewayRequest(EncodeGatewayRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET read == DecodeHeartbeat(EncodeHeartbeat(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp7 ==
    \A message \in CheckedRequestHeaderComp7 :
        LET read == DecodeRequestHeaderComp7(EncodeRequestHeaderComp7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire Session List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireSessionListRequest ==
    \A message \in CheckedInquireSessionListRequest :
        LET read == DecodeInquireSessionListRequest(EncodeInquireSessionListRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp8 ==
    \A message \in CheckedRequestHeaderComp8 :
        LET read == DecodeRequestHeaderComp8(EncodeRequestHeaderComp8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequest ==
    \A message \in CheckedLogonRequest :
        LET read == DecodeLogonRequest(EncodeLogonRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp9 ==
    \A message \in CheckedRequestHeaderComp9 :
        LET read == DecodeRequestHeaderComp9(EncodeRequestHeaderComp9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp10 ==
    \A message \in CheckedRequestHeaderComp10 :
        LET read == DecodeRequestHeaderComp10(EncodeRequestHeaderComp10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Entry Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteEntryGrpComp ==
    \A message \in CheckedQuoteEntryGrpComp :
        LET read == DecodeQuoteEntryGrpComp(EncodeQuoteEntryGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuoteRequest ==
    \A message \in CheckedMassQuoteRequest :
        LET read == DecodeMassQuoteRequest(EncodeMassQuoteRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp11 ==
    \A message \in CheckedRequestHeaderComp11 :
        LET read == DecodeRequestHeaderComp11(EncodeRequestHeaderComp11(message))
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

(* Every Modify Order Complex Request decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderComplexRequest ==
    \A message \in CheckedModifyOrderComplexRequest :
        LET read == DecodeModifyOrderComplexRequest(EncodeModifyOrderComplexRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp12 ==
    \A message \in CheckedRequestHeaderComp12 :
        LET read == DecodeRequestHeaderComp12(EncodeRequestHeaderComp12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Single Request decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderSingleRequest ==
    \A message \in CheckedModifyOrderSingleRequest :
        LET read == DecodeModifyOrderSingleRequest(EncodeModifyOrderSingleRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp13 ==
    \A message \in CheckedRequestHeaderComp13 :
        LET read == DecodeRequestHeaderComp13(EncodeRequestHeaderComp13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Single Short Request decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderSingleShortRequest ==
    \A message \in CheckedModifyOrderSingleShortRequest :
        LET read == DecodeModifyOrderSingleShortRequest(EncodeModifyOrderSingleShortRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp14 ==
    \A message \in CheckedRequestHeaderComp14 :
        LET read == DecodeRequestHeaderComp14(EncodeRequestHeaderComp14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Ord Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegOrdGrpComp ==
    \A message \in CheckedMultiLegOrdGrpComp :
        LET read == DecodeMultiLegOrdGrpComp(EncodeMultiLegOrdGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multi Leg Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMultiLegOrderRequest ==
    \A message \in CheckedMultiLegOrderRequest :
        LET read == DecodeMultiLegOrderRequest(EncodeMultiLegOrderRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp15 ==
    \A message \in CheckedRequestHeaderComp15 :
        LET read == DecodeRequestHeaderComp15(EncodeRequestHeaderComp15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Ord Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripLegOrdGrpComp2 ==
    \A message \in CheckedLegOrdGrpComp2 :
        LET read == DecodeLegOrdGrpComp2(EncodeLegOrdGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Complex Request decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderComplexRequest ==
    \A message \in CheckedNewOrderComplexRequest :
        LET read == DecodeNewOrderComplexRequest(EncodeNewOrderComplexRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp16 ==
    \A message \in CheckedRequestHeaderComp16 :
        LET read == DecodeRequestHeaderComp16(EncodeRequestHeaderComp16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Single Request decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderSingleRequest ==
    \A message \in CheckedNewOrderSingleRequest :
        LET read == DecodeNewOrderSingleRequest(EncodeNewOrderSingleRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp17 ==
    \A message \in CheckedRequestHeaderComp17 :
        LET read == DecodeRequestHeaderComp17(EncodeRequestHeaderComp17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Single Short Request decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderSingleShortRequest ==
    \A message \in CheckedNewOrderSingleShortRequest :
        LET read == DecodeNewOrderSingleShortRequest(EncodeNewOrderSingleShortRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp18 ==
    \A message \in CheckedRequestHeaderComp18 :
        LET read == DecodeRequestHeaderComp18(EncodeRequestHeaderComp18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Me Message Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitMeMessageRequest ==
    \A message \in CheckedRetransmitMeMessageRequest :
        LET read == DecodeRetransmitMeMessageRequest(EncodeRetransmitMeMessageRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp19 ==
    \A message \in CheckedRequestHeaderComp19 :
        LET read == DecodeRequestHeaderComp19(EncodeRequestHeaderComp19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRequest ==
    \A message \in CheckedRetransmitRequest :
        LET read == DecodeRetransmitRequest(EncodeRetransmitRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp20 ==
    \A message \in CheckedRequestHeaderComp20 :
        LET read == DecodeRequestHeaderComp20(EncodeRequestHeaderComp20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Password Change Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionPasswordChangeRequest ==
    \A message \in CheckedSessionPasswordChangeRequest :
        LET read == DecodeSessionPasswordChangeRequest(EncodeSessionPasswordChangeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp21 ==
    \A message \in CheckedRequestHeaderComp21 :
        LET read == DecodeRequestHeaderComp21(EncodeRequestHeaderComp21(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Registration Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionRegistrationRequest ==
    \A message \in CheckedSessionRegistrationRequest :
        LET read == DecodeSessionRegistrationRequest(EncodeSessionRegistrationRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp22 ==
    \A message \in CheckedRequestHeaderComp22 :
        LET read == DecodeRequestHeaderComp22(EncodeRequestHeaderComp22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscribe Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscribeRequest ==
    \A message \in CheckedSubscribeRequest :
        LET read == DecodeSubscribeRequest(EncodeSubscribeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp23 ==
    \A message \in CheckedRequestHeaderComp23 :
        LET read == DecodeRequestHeaderComp23(EncodeRequestHeaderComp23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsubscribe Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsubscribeRequest ==
    \A message \in CheckedUnsubscribeRequest :
        LET read == DecodeUnsubscribeRequest(EncodeUnsubscribeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp24 ==
    \A message \in CheckedRequestHeaderComp24 :
        LET read == DecodeRequestHeaderComp24(EncodeRequestHeaderComp24(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLoginRequest ==
    \A message \in CheckedUserLoginRequest :
        LET read == DecodeUserLoginRequest(EncodeUserLoginRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp25 ==
    \A message \in CheckedRequestHeaderComp25 :
        LET read == DecodeRequestHeaderComp25(EncodeRequestHeaderComp25(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLogoutRequest ==
    \A message \in CheckedUserLogoutRequest :
        LET read == DecodeUserLogoutRequest(EncodeUserLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp26 ==
    \A message \in CheckedRequestHeaderComp26 :
        LET read == DecodeRequestHeaderComp26(EncodeRequestHeaderComp26(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Password Change Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUserPasswordChangeRequest ==
    \A message \in CheckedUserPasswordChangeRequest :
        LET read == DecodeUserPasswordChangeRequest(EncodeUserPasswordChangeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientMessage ==
    \A message \in CheckedClientMessage :
        LET read == DecodeClientMessage(EncodeClientMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPacket ==
    \A message \in CheckedClientPacket :
        LET read == DecodeClientPacket(EncodeClientPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Client Payload is selected by the Template Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Body Len is written from the bytes it frames *)
FramesClientMessage ==
    \A message \in CheckedClientMessage :
        LET bytes == EncodeClientMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 4)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
