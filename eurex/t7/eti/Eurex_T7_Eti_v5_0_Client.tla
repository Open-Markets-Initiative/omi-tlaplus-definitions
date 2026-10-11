--------------------- MODULE Eurex_T7_Eti_v5_0_Client ----------------------
(***************************************************************************)
(* Eurex Exchange Enhanced Trading Interface v5.0                          *)
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
(* Note: Add Complex Instrument Request fills what is left of the frame    *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Add Flexible Instrument Request fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Approve Tes Trade Request fills what is left of the frame Body    *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Cross Request fills what is left of the frame Body Len states,    *)
(* which is what it is read from.                                          *)
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
(* Note: Delete Tes Trade Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Enter Tes Trade Request fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Gateway Request fills what is left of the frame Body Len states,  *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Heartbeat fills what is left of the frame Body Len states, which  *)
(* is what it is read from.                                                *)
(*                                                                         *)
(* Note: Inquire Enrichment Rule Id List Request fills what is left of the *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Inquire Mm Parameter Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Inquire Session List Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Inquire User Request fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Logon Request fills what is left of the frame Body Len states,    *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Logout Request fills what is left of the frame Body Len states,   *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Mm Parameter Definition Request fills what is left of the frame   *)
(* Body Len states, which is what it is read from.                         *)
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
(* Note: Modify Tes Trade Request fills what is left of the frame Body Len *)
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
(* Note: Quote Activation Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Rfq Request fills what is left of the frame Body Len states,      *)
(* which is what it is read from.                                          *)
(*                                                                         *)
(* Note: Retransmit Me Message Request fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Retransmit Request fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Subscribe Request fills what is left of the frame Body Len        *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Unsubscribe Request fills what is left of the frame Body Len      *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Upload Tes Trade Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Login Request fills what is left of the frame Body Len       *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: User Logout Request fills what is left of the frame Body Len      *)
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
(* Instrmt Leg Grp Comp: 32 bytes                                          *)
(***************************************************************************)

InstrmtLegGrpComp ==
    [ legSecurityId   : Sample(8),
      legPrice        : Sample(8),
      legSymbol       : Sample(4),
      legRatioQty     : Sample(4),
      legSide         : Sample(1),
      legSecurityType : Sample(1),
      pad6            : Sample(6) ]

EncodeInstrmtLegGrpComp(message) ==
    message.legSecurityId
        \o message.legPrice
        \o message.legSymbol
        \o message.legRatioQty
        \o message.legSide
        \o message.legSecurityType
        \o message.pad6

DecodeInstrmtLegGrpComp(bytes) ==
    LET legSecurityId == ReadBytes(bytes, 8) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legSecurityId.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legSymbol == ReadBytes(legPrice.rest, 4) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSymbol.rest, 4) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSide == ReadBytes(legRatioQty.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legSide.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET pad6 == ReadBytes(legSecurityType.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ legSecurityId   |-> legSecurityId.value,
         legPrice        |-> legPrice.value,
         legSymbol       |-> legSymbol.value,
         legRatioQty     |-> legRatioQty.value,
         legSide         |-> legSide.value,
         legSecurityType |-> legSecurityType.value,
         pad6            |-> pad6.value ], pad6.rest)

ZeroInstrmtLegGrpComp ==
    [ legSecurityId   |-> [i \in 1 .. 8 |-> 0],
      legPrice        |-> [i \in 1 .. 8 |-> 0],
      legSymbol       |-> [i \in 1 .. 4 |-> 0],
      legRatioQty     |-> [i \in 1 .. 4 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0],
      pad6            |-> [i \in 1 .. 6 |-> 0] ]

(* Instrmt Leg Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrmtLegGrpComp ==
    { ZeroInstrmtLegGrpComp }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSecurityId = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSymbol = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legRatioQty = one] : one \in Sample(4) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroInstrmtLegGrpComp EXCEPT !.pad6 = one] : one \in Sample(6) }

(* A run of Instrmt Leg Grp Comp, written one after another *)
RECURSIVE EncodeInstrmtLegGrpCompList(_)
EncodeInstrmtLegGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrmtLegGrpComp(Head(messages)) \o EncodeInstrmtLegGrpCompList(Tail(messages))

(* As many Instrmt Leg Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrmtLegGrpCompList(_, _)
ReadInstrmtLegGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrmtLegGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrmtLegGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrmt Leg Grp Comp of each kind, for the lists that carry them *)
OneInstrmtLegGrpComp == { ZeroInstrmtLegGrpComp }

(***************************************************************************)
(* Add Complex Instrument Request                                          *)
(***************************************************************************)

AddComplexInstrumentRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp,
      complianceId      : Sample(8),
      marketSegmentId   : Sample(4),
      securitySubType   : Sample(4),
      productComplex    : Sample(1),
      complianceText    : Sample(20),
      pad2v2            : Sample(2),
      instrmtLegGrpComp : SampleLists(OneInstrmtLegGrpComp) ]

EncodeAddComplexInstrumentRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp(message.requestHeaderComp)
        \o message.complianceId
        \o message.marketSegmentId
        \o message.securitySubType
        \o message.productComplex
        \o EncodeUIntBE(Len(message.instrmtLegGrpComp), 1)
        \o message.complianceText
        \o message.pad2v2
        \o EncodeInstrmtLegGrpCompList(message.instrmtLegGrpComp)

DecodeAddComplexInstrumentRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET complianceId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(marketSegmentId.rest, 4) IN IF ~securitySubType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(securitySubType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(productComplex.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET complianceText == ReadBytes(noLegs.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(complianceText.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET instrmtLegGrpComp == ReadInstrmtLegGrpCompList(pad2v2.rest, noLegs.value) IN IF ~instrmtLegGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         complianceId      |-> complianceId.value,
         marketSegmentId   |-> marketSegmentId.value,
         securitySubType   |-> securitySubType.value,
         productComplex    |-> productComplex.value,
         complianceText    |-> complianceText.value,
         pad2v2            |-> pad2v2.value,
         instrmtLegGrpComp |-> instrmtLegGrpComp.value ], instrmtLegGrpComp.rest)

ZeroAddComplexInstrumentRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp,
      complianceId      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      securitySubType   |-> [i \in 1 .. 4 |-> 0],
      productComplex    |-> [i \in 1 .. 1 |-> 0],
      complianceText    |-> [i \in 1 .. 20 |-> 0],
      pad2v2            |-> [i \in 1 .. 2 |-> 0],
      instrmtLegGrpComp |-> << >> ]

(* Add Complex Instrument Request at zero, then each field in turn at the values it is checked at *)
CheckedAddComplexInstrumentRequest ==
    { ZeroAddComplexInstrumentRequest }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.securitySubType = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroAddComplexInstrumentRequest EXCEPT !.instrmtLegGrpComp = one] : one \in SampleLists(OneInstrmtLegGrpComp) }

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
(* Add Flexible Instrument Request: 66 bytes                               *)
(***************************************************************************)

AddFlexibleInstrumentRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp2,
      complianceId      : Sample(8),
      strikePrice       : Sample(8),
      marketSegmentId   : Sample(4),
      maturityDate      : Sample(4),
      settlMethod       : Sample(1),
      optAttribute      : Sample(1),
      putOrCall         : Sample(1),
      exerciseStyle     : Sample(1),
      complianceText    : Sample(20) ]

EncodeAddFlexibleInstrumentRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp2(message.requestHeaderComp)
        \o message.complianceId
        \o message.strikePrice
        \o message.marketSegmentId
        \o message.maturityDate
        \o message.settlMethod
        \o message.optAttribute
        \o message.putOrCall
        \o message.exerciseStyle
        \o message.complianceText

DecodeAddFlexibleInstrumentRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp2(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET complianceId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(complianceId.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(strikePrice.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET settlMethod == ReadBytes(maturityDate.rest, 1) IN IF ~settlMethod.ok THEN Fail ELSE
    LET optAttribute == ReadBytes(settlMethod.rest, 1) IN IF ~optAttribute.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(optAttribute.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(putOrCall.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET complianceText == ReadBytes(exerciseStyle.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         complianceId      |-> complianceId.value,
         strikePrice       |-> strikePrice.value,
         marketSegmentId   |-> marketSegmentId.value,
         maturityDate      |-> maturityDate.value,
         settlMethod       |-> settlMethod.value,
         optAttribute      |-> optAttribute.value,
         putOrCall         |-> putOrCall.value,
         exerciseStyle     |-> exerciseStyle.value,
         complianceText    |-> complianceText.value ], complianceText.rest)

ZeroAddFlexibleInstrumentRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp2,
      complianceId      |-> [i \in 1 .. 8 |-> 0],
      strikePrice       |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      maturityDate      |-> [i \in 1 .. 4 |-> 0],
      settlMethod       |-> [i \in 1 .. 1 |-> 0],
      optAttribute      |-> [i \in 1 .. 1 |-> 0],
      putOrCall         |-> [i \in 1 .. 1 |-> 0],
      exerciseStyle     |-> [i \in 1 .. 1 |-> 0],
      complianceText    |-> [i \in 1 .. 20 |-> 0] ]

(* Add Flexible Instrument Request at zero, then each field in turn at the values it is checked at *)
CheckedAddFlexibleInstrumentRequest ==
    { ZeroAddFlexibleInstrumentRequest }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp2 }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.settlMethod = one] : one \in Sample(1) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.optAttribute = one] : one \in Sample(1) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroAddFlexibleInstrumentRequest EXCEPT !.complianceText = one] : one \in Sample(20) }

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
(* Approve Tes Trade Request: 202 bytes                                    *)
(***************************************************************************)

ApproveTesTradeRequest ==
    [ networkMsgId                : Sample(8),
      pad2                        : Sample(2),
      requestHeaderComp           : RequestHeaderComp3,
      complianceId                : Sample(8),
      packageId                   : Sample(4),
      allocId                     : Sample(4),
      allocQty                    : Sample(4),
      tesExecId                   : Sample(4),
      marketSegmentId             : Sample(4),
      relatedMarketSegmentId      : Sample(4),
      trdType                     : Sample(2),
      tradingCapacity             : Sample(1),
      tradeReportType             : Sample(1),
      side                        : Sample(1),
      tradeReportId               : Sample(20),
      positionEffect              : Sample(1),
      partyExecutingFirm          : Sample(5),
      partyExecutingTrader        : Sample(6),
      account                     : Sample(2),
      freeText1                   : Sample(12),
      freeText2                   : Sample(12),
      freeText3                   : Sample(12),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdPositionAccount      : Sample(32),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      partyIdLocationId           : Sample(2),
      custOrderHandlingInst       : Sample(1),
      complianceText              : Sample(20),
      pad1                        : Sample(1) ]

EncodeApproveTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp3(message.requestHeaderComp)
        \o message.complianceId
        \o message.packageId
        \o message.allocId
        \o message.allocQty
        \o message.tesExecId
        \o message.marketSegmentId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.tradingCapacity
        \o message.tradeReportType
        \o message.side
        \o message.tradeReportId
        \o message.positionEffect
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.account
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdPositionAccount
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.pad1

DecodeApproveTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp3(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET complianceId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET packageId == ReadBytes(complianceId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET allocId == ReadBytes(packageId.rest, 4) IN IF ~allocId.ok THEN Fail ELSE
    LET allocQty == ReadBytes(allocId.rest, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(allocQty.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(tesExecId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(marketSegmentId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(trdType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradingCapacity.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET side == ReadBytes(tradeReportType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(side.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(tradeReportId.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(positionEffect.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET account == ReadBytes(partyExecutingTrader.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(account.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(freeText3.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(partyIdTakeUpTradingFirm.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdPositionAccount.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(partyIdBeneficiary.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad1 == ReadBytes(complianceText.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId                |-> networkMsgId.value,
         pad2                        |-> pad2.value,
         requestHeaderComp           |-> requestHeaderComp.value,
         complianceId                |-> complianceId.value,
         packageId                   |-> packageId.value,
         allocId                     |-> allocId.value,
         allocQty                    |-> allocQty.value,
         tesExecId                   |-> tesExecId.value,
         marketSegmentId             |-> marketSegmentId.value,
         relatedMarketSegmentId      |-> relatedMarketSegmentId.value,
         trdType                     |-> trdType.value,
         tradingCapacity             |-> tradingCapacity.value,
         tradeReportType             |-> tradeReportType.value,
         side                        |-> side.value,
         tradeReportId               |-> tradeReportId.value,
         positionEffect              |-> positionEffect.value,
         partyExecutingFirm          |-> partyExecutingFirm.value,
         partyExecutingTrader        |-> partyExecutingTrader.value,
         account                     |-> account.value,
         freeText1                   |-> freeText1.value,
         freeText2                   |-> freeText2.value,
         freeText3                   |-> freeText3.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdPositionAccount      |-> partyIdPositionAccount.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         complianceText              |-> complianceText.value,
         pad1                        |-> pad1.value ], pad1.rest)

ZeroApproveTesTradeRequest ==
    [ networkMsgId                |-> [i \in 1 .. 8 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp           |-> ZeroRequestHeaderComp3,
      complianceId                |-> [i \in 1 .. 8 |-> 0],
      packageId                   |-> [i \in 1 .. 4 |-> 0],
      allocId                     |-> [i \in 1 .. 4 |-> 0],
      allocQty                    |-> [i \in 1 .. 4 |-> 0],
      tesExecId                   |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId      |-> [i \in 1 .. 4 |-> 0],
      trdType                     |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      tradeReportType             |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      tradeReportId               |-> [i \in 1 .. 20 |-> 0],
      positionEffect              |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm          |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader        |-> [i \in 1 .. 6 |-> 0],
      account                     |-> [i \in 1 .. 2 |-> 0],
      freeText1                   |-> [i \in 1 .. 12 |-> 0],
      freeText2                   |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdPositionAccount      |-> [i \in 1 .. 32 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      complianceText              |-> [i \in 1 .. 20 |-> 0],
      pad1                        |-> [i \in 1 .. 1 |-> 0] ]

(* Approve Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedApproveTesTradeRequest ==
    { ZeroApproveTesTradeRequest }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp3 }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.allocId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

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
(* Cross Request: 66 bytes                                                 *)
(***************************************************************************)

CrossRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp4,
      securityId        : Sample(8),
      complianceId      : Sample(8),
      marketSegmentId   : Sample(4),
      orderQty          : Sample(4),
      complianceText    : Sample(20),
      pad4              : Sample(4) ]

EncodeCrossRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp4(message.requestHeaderComp)
        \o message.securityId
        \o message.complianceId
        \o message.marketSegmentId
        \o message.orderQty
        \o message.complianceText
        \o message.pad4

DecodeCrossRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp4(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(securityId.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET complianceText == ReadBytes(orderQty.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad4 == ReadBytes(complianceText.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         securityId        |-> securityId.value,
         complianceId      |-> complianceId.value,
         marketSegmentId   |-> marketSegmentId.value,
         orderQty          |-> orderQty.value,
         complianceText    |-> complianceText.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroCrossRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp4,
      securityId        |-> [i \in 1 .. 8 |-> 0],
      complianceId      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      orderQty          |-> [i \in 1 .. 4 |-> 0],
      complianceText    |-> [i \in 1 .. 20 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Cross Request at zero, then each field in turn at the values it is checked at *)
CheckedCrossRequest ==
    { ZeroCrossRequest }
        \cup { [ZeroCrossRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroCrossRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp4 }
        \cup { [ZeroCrossRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroCrossRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroCrossRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroCrossRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

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
(* Delete All Order Request: 58 bytes                                      *)
(***************************************************************************)

DeleteAllOrderRequest ==
    [ networkMsgId                 : Sample(8),
      pad2                         : Sample(2),
      requestHeaderComp            : RequestHeaderComp5,
      securityId                   : Sample(8),
      price                        : Sample(8),
      complianceId                 : Sample(8),
      marketSegmentId              : Sample(4),
      targetPartyIdSessionId       : Sample(4),
      targetPartyIdExecutingTrader : Sample(4),
      side                         : Sample(1),
      pad3                         : Sample(3) ]

EncodeDeleteAllOrderRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp5(message.requestHeaderComp)
        \o message.securityId
        \o message.price
        \o message.complianceId
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.targetPartyIdExecutingTrader
        \o message.side
        \o message.pad3

DecodeDeleteAllOrderRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp5(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET complianceId == ReadBytes(price.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET targetPartyIdExecutingTrader == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET side == ReadBytes(targetPartyIdExecutingTrader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad3 == ReadBytes(side.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ networkMsgId                 |-> networkMsgId.value,
         pad2                         |-> pad2.value,
         requestHeaderComp            |-> requestHeaderComp.value,
         securityId                   |-> securityId.value,
         price                        |-> price.value,
         complianceId                 |-> complianceId.value,
         marketSegmentId              |-> marketSegmentId.value,
         targetPartyIdSessionId       |-> targetPartyIdSessionId.value,
         targetPartyIdExecutingTrader |-> targetPartyIdExecutingTrader.value,
         side                         |-> side.value,
         pad3                         |-> pad3.value ], pad3.rest)

ZeroDeleteAllOrderRequest ==
    [ networkMsgId                 |-> [i \in 1 .. 8 |-> 0],
      pad2                         |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp            |-> ZeroRequestHeaderComp5,
      securityId                   |-> [i \in 1 .. 8 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      complianceId                 |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId              |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId       |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdExecutingTrader |-> [i \in 1 .. 4 |-> 0],
      side                         |-> [i \in 1 .. 1 |-> 0],
      pad3                         |-> [i \in 1 .. 3 |-> 0] ]

(* Delete All Order Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderRequest ==
    { ZeroDeleteAllOrderRequest }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp5 }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

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
(* Delete All Quote Request: 34 bytes                                      *)
(***************************************************************************)

DeleteAllQuoteRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp6,
      complianceId           : Sample(8),
      marketSegmentId        : Sample(4),
      targetPartyIdSessionId : Sample(4) ]

EncodeDeleteAllQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp6(message.requestHeaderComp)
        \o message.complianceId
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId

DecodeDeleteAllQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp6(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET complianceId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         complianceId           |-> complianceId.value,
         marketSegmentId        |-> marketSegmentId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value ], targetPartyIdSessionId.rest)

ZeroDeleteAllQuoteRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp6,
      complianceId           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Delete All Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllQuoteRequest ==
    { ZeroDeleteAllQuoteRequest }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp6 }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }

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
(* Delete Order Complex Request: 66 bytes                                  *)
(***************************************************************************)

DeleteOrderComplexRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp7,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      securityId             : Sample(8),
      complianceId           : Sample(8),
      marketSegmentId        : Sample(4),
      targetPartyIdSessionId : Sample(4) ]

EncodeDeleteOrderComplexRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp7(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.complianceId
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId

DecodeDeleteOrderComplexRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp7(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(securityId.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         securityId             |-> securityId.value,
         complianceId           |-> complianceId.value,
         marketSegmentId        |-> marketSegmentId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value ], targetPartyIdSessionId.rest)

ZeroDeleteOrderComplexRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp7,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      securityId             |-> [i \in 1 .. 8 |-> 0],
      complianceId           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Delete Order Complex Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderComplexRequest ==
    { ZeroDeleteOrderComplexRequest }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp7 }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderComplexRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }

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
(* Delete Order Single Request: 66 bytes                                   *)
(***************************************************************************)

DeleteOrderSingleRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp8,
      orderId                : Sample(8),
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      complianceId           : Sample(8),
      marketSegmentId        : Sample(4),
      simpleSecurityId       : Sample(4),
      targetPartyIdSessionId : Sample(4),
      pad4                   : Sample(4) ]

EncodeDeleteOrderSingleRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp8(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.complianceId
        \o message.marketSegmentId
        \o message.simpleSecurityId
        \o message.targetPartyIdSessionId
        \o message.pad4

DecodeDeleteOrderSingleRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp8(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(origClOrdId.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(marketSegmentId.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(simpleSecurityId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         orderId                |-> orderId.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         complianceId           |-> complianceId.value,
         marketSegmentId        |-> marketSegmentId.value,
         simpleSecurityId       |-> simpleSecurityId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value,
         pad4                   |-> pad4.value ], pad4.rest)

ZeroDeleteOrderSingleRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp8,
      orderId                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      complianceId           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId       |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0],
      pad4                   |-> [i \in 1 .. 4 |-> 0] ]

(* Delete Order Single Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderSingleRequest ==
    { ZeroDeleteOrderSingleRequest }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp8 }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

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
(* Delete Tes Trade Request: 58 bytes                                      *)
(***************************************************************************)

DeleteTesTradeRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp9,
      packageId              : Sample(4),
      marketSegmentId        : Sample(4),
      tesExecId              : Sample(4),
      relatedMarketSegmentId : Sample(4),
      trdType                : Sample(2),
      tradeReportType        : Sample(1),
      tradeReportId          : Sample(20),
      pad1                   : Sample(1) ]

EncodeDeleteTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp9(message.requestHeaderComp)
        \o message.packageId
        \o message.marketSegmentId
        \o message.tesExecId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.tradeReportType
        \o message.tradeReportId
        \o message.pad1

DecodeDeleteTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp9(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET packageId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(marketSegmentId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(tesExecId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportType.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(tradeReportId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         packageId              |-> packageId.value,
         marketSegmentId        |-> marketSegmentId.value,
         tesExecId              |-> tesExecId.value,
         relatedMarketSegmentId |-> relatedMarketSegmentId.value,
         trdType                |-> trdType.value,
         tradeReportType        |-> tradeReportType.value,
         tradeReportId          |-> tradeReportId.value,
         pad1                   |-> pad1.value ], pad1.rest)

ZeroDeleteTesTradeRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp9,
      packageId              |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      tesExecId              |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId |-> [i \in 1 .. 4 |-> 0],
      trdType                |-> [i \in 1 .. 2 |-> 0],
      tradeReportType        |-> [i \in 1 .. 1 |-> 0],
      tradeReportId          |-> [i \in 1 .. 20 |-> 0],
      pad1                   |-> [i \in 1 .. 1 |-> 0] ]

(* Delete Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteTesTradeRequest ==
    { ZeroDeleteTesTradeRequest }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp9 }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

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
(* Side Alloc Grp Comp: 24 bytes                                           *)
(***************************************************************************)

SideAllocGrpComp ==
    [ individualAllocId    : Sample(4),
      allocQty             : Sample(4),
      side                 : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeSideAllocGrpComp(message) ==
    message.individualAllocId
        \o message.allocQty
        \o message.side
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeSideAllocGrpComp(bytes) ==
    LET individualAllocId == ReadBytes(bytes, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET allocQty == ReadBytes(individualAllocId.rest, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET side == ReadBytes(allocQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ individualAllocId    |-> individualAllocId.value,
         allocQty             |-> allocQty.value,
         side                 |-> side.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroSideAllocGrpComp ==
    [ individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      allocQty             |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideAllocGrpComp ==
    { ZeroSideAllocGrpComp }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Side Alloc Grp Comp, written one after another *)
RECURSIVE EncodeSideAllocGrpCompList(_)
EncodeSideAllocGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSideAllocGrpComp(Head(messages)) \o EncodeSideAllocGrpCompList(Tail(messages))

(* As many Side Alloc Grp Comp as the field that counts them says *)
RECURSIVE ReadSideAllocGrpCompList(_, _)
ReadSideAllocGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSideAllocGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSideAllocGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Side Alloc Grp Comp of each kind, for the lists that carry them *)
OneSideAllocGrpComp == { ZeroSideAllocGrpComp }

(***************************************************************************)
(* Instrument Event Grp Comp: 8 bytes                                      *)
(***************************************************************************)

InstrumentEventGrpComp ==
    [ eventDate : Sample(4),
      eventType : Sample(1),
      pad3      : Sample(3) ]

EncodeInstrumentEventGrpComp(message) ==
    message.eventDate
        \o message.eventType
        \o message.pad3

DecodeInstrumentEventGrpComp(bytes) ==
    LET eventDate == ReadBytes(bytes, 4) IN IF ~eventDate.ok THEN Fail ELSE
    LET eventType == ReadBytes(eventDate.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET pad3 == ReadBytes(eventType.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ eventDate |-> eventDate.value,
         eventType |-> eventType.value,
         pad3      |-> pad3.value ], pad3.rest)

ZeroInstrumentEventGrpComp ==
    [ eventDate |-> [i \in 1 .. 4 |-> 0],
      eventType |-> [i \in 1 .. 1 |-> 0],
      pad3      |-> [i \in 1 .. 3 |-> 0] ]

(* Instrument Event Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentEventGrpComp ==
    { ZeroInstrumentEventGrpComp }
        \cup { [ZeroInstrumentEventGrpComp EXCEPT !.eventDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentEventGrpComp EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentEventGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Instrument Event Grp Comp, written one after another *)
RECURSIVE EncodeInstrumentEventGrpCompList(_)
EncodeInstrumentEventGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentEventGrpComp(Head(messages)) \o EncodeInstrumentEventGrpCompList(Tail(messages))

(* As many Instrument Event Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrumentEventGrpCompList(_, _)
ReadInstrumentEventGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentEventGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentEventGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Event Grp Comp of each kind, for the lists that carry them *)
OneInstrumentEventGrpComp == { ZeroInstrumentEventGrpComp }

(***************************************************************************)
(* Instrument Attribute Grp Comp: 40 bytes                                 *)
(***************************************************************************)

InstrumentAttributeGrpComp ==
    [ instrAttribType  : Sample(1),
      instrAttribValue : Sample(32),
      pad7             : Sample(7) ]

EncodeInstrumentAttributeGrpComp(message) ==
    message.instrAttribType
        \o message.instrAttribValue
        \o message.pad7

DecodeInstrumentAttributeGrpComp(bytes) ==
    LET instrAttribType == ReadBytes(bytes, 1) IN IF ~instrAttribType.ok THEN Fail ELSE
    LET instrAttribValue == ReadBytes(instrAttribType.rest, 32) IN IF ~instrAttribValue.ok THEN Fail ELSE
    LET pad7 == ReadBytes(instrAttribValue.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ instrAttribType  |-> instrAttribType.value,
         instrAttribValue |-> instrAttribValue.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroInstrumentAttributeGrpComp ==
    [ instrAttribType  |-> [i \in 1 .. 1 |-> 0],
      instrAttribValue |-> [i \in 1 .. 32 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Instrument Attribute Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentAttributeGrpComp ==
    { ZeroInstrumentAttributeGrpComp }
        \cup { [ZeroInstrumentAttributeGrpComp EXCEPT !.instrAttribType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentAttributeGrpComp EXCEPT !.instrAttribValue = one] : one \in Sample(32) }
        \cup { [ZeroInstrumentAttributeGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Instrument Attribute Grp Comp, written one after another *)
RECURSIVE EncodeInstrumentAttributeGrpCompList(_)
EncodeInstrumentAttributeGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentAttributeGrpComp(Head(messages)) \o EncodeInstrumentAttributeGrpCompList(Tail(messages))

(* As many Instrument Attribute Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrumentAttributeGrpCompList(_, _)
ReadInstrumentAttributeGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentAttributeGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentAttributeGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Attribute Grp Comp of each kind, for the lists that carry them *)
OneInstrumentAttributeGrpComp == { ZeroInstrumentAttributeGrpComp }

(***************************************************************************)
(* Underlying Stip Grp Comp: 40 bytes                                      *)
(***************************************************************************)

UnderlyingStipGrpComp ==
    [ underlyingStipValue : Sample(32),
      underlyingStipType  : Sample(7),
      pad1                : Sample(1) ]

EncodeUnderlyingStipGrpComp(message) ==
    message.underlyingStipValue
        \o message.underlyingStipType
        \o message.pad1

DecodeUnderlyingStipGrpComp(bytes) ==
    LET underlyingStipValue == ReadBytes(bytes, 32) IN IF ~underlyingStipValue.ok THEN Fail ELSE
    LET underlyingStipType == ReadBytes(underlyingStipValue.rest, 7) IN IF ~underlyingStipType.ok THEN Fail ELSE
    LET pad1 == ReadBytes(underlyingStipType.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ underlyingStipValue |-> underlyingStipValue.value,
         underlyingStipType  |-> underlyingStipType.value,
         pad1                |-> pad1.value ], pad1.rest)

ZeroUnderlyingStipGrpComp ==
    [ underlyingStipValue |-> [i \in 1 .. 32 |-> 0],
      underlyingStipType  |-> [i \in 1 .. 7 |-> 0],
      pad1                |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Stip Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingStipGrpComp ==
    { ZeroUnderlyingStipGrpComp }
        \cup { [ZeroUnderlyingStipGrpComp EXCEPT !.underlyingStipValue = one] : one \in Sample(32) }
        \cup { [ZeroUnderlyingStipGrpComp EXCEPT !.underlyingStipType = one] : one \in Sample(7) }
        \cup { [ZeroUnderlyingStipGrpComp EXCEPT !.pad1 = one] : one \in Sample(1) }

(* A run of Underlying Stip Grp Comp, written one after another *)
RECURSIVE EncodeUnderlyingStipGrpCompList(_)
EncodeUnderlyingStipGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnderlyingStipGrpComp(Head(messages)) \o EncodeUnderlyingStipGrpCompList(Tail(messages))

(* As many Underlying Stip Grp Comp as the field that counts them says *)
RECURSIVE ReadUnderlyingStipGrpCompList(_, _)
ReadUnderlyingStipGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnderlyingStipGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnderlyingStipGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Underlying Stip Grp Comp of each kind, for the lists that carry them *)
OneUnderlyingStipGrpComp == { ZeroUnderlyingStipGrpComp }

(***************************************************************************)
(* Enter Tes Trade Request                                                 *)
(***************************************************************************)

EnterTesTradeRequest ==
    [ networkMsgId               : Sample(8),
      pad2                       : Sample(2),
      requestHeaderComp          : RequestHeaderComp10,
      securityId                 : Sample(8),
      lastPx                     : Sample(8),
      transBkdTime               : Sample(8),
      underlyingPx               : Sample(8),
      underlyingQty              : Sample(8),
      relatedClosePrice          : Sample(8),
      marketSegmentId            : Sample(4),
      underlyingSettlementDate   : Sample(4),
      underlyingMaturityDate     : Sample(4),
      relatedTradeId             : Sample(4),
      relatedMarketSegmentId     : Sample(4),
      relatedTradeQuantity       : Sample(4),
      trdType                    : Sample(2),
      productComplex             : Sample(1),
      tradeReportType            : Sample(1),
      tradePublishIndicator      : Sample(1),
      partyIdSettlementLocation  : Sample(1),
      hedgeType                  : Sample(1),
      tradeReportText            : Sample(20),
      tradeReportId              : Sample(20),
      underlyingSecurityId       : Sample(12),
      underlyingSecurityDesc     : Sample(30),
      underlyingCurrency         : Sample(3),
      underlyingIssuer           : Sample(30),
      pad2v2                     : Sample(2),
      sideAllocGrpComp           : SampleLists(OneSideAllocGrpComp),
      instrumentEventGrpComp     : SampleLists(OneInstrumentEventGrpComp),
      instrumentAttributeGrpComp : SampleLists(OneInstrumentAttributeGrpComp),
      underlyingStipGrpComp      : SampleLists(OneUnderlyingStipGrpComp) ]

EncodeEnterTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp10(message.requestHeaderComp)
        \o message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.underlyingPx
        \o message.underlyingQty
        \o message.relatedClosePrice
        \o message.marketSegmentId
        \o message.underlyingSettlementDate
        \o message.underlyingMaturityDate
        \o message.relatedTradeId
        \o message.relatedMarketSegmentId
        \o message.relatedTradeQuantity
        \o message.trdType
        \o message.productComplex
        \o message.tradeReportType
        \o message.tradePublishIndicator
        \o EncodeUIntBE(Len(message.sideAllocGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrumentEventGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrumentAttributeGrpComp), 1)
        \o EncodeUIntBE(Len(message.underlyingStipGrpComp), 1)
        \o message.partyIdSettlementLocation
        \o message.hedgeType
        \o message.tradeReportText
        \o message.tradeReportId
        \o message.underlyingSecurityId
        \o message.underlyingSecurityDesc
        \o message.underlyingCurrency
        \o message.underlyingIssuer
        \o message.pad2v2
        \o EncodeSideAllocGrpCompList(message.sideAllocGrpComp)
        \o EncodeInstrumentEventGrpCompList(message.instrumentEventGrpComp)
        \o EncodeInstrumentAttributeGrpCompList(message.instrumentAttributeGrpComp)
        \o EncodeUnderlyingStipGrpCompList(message.underlyingStipGrpComp)

DecodeEnterTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp10(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET underlyingPx == ReadBytes(transBkdTime.rest, 8) IN IF ~underlyingPx.ok THEN Fail ELSE
    LET underlyingQty == ReadBytes(underlyingPx.rest, 8) IN IF ~underlyingQty.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(underlyingQty.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(relatedClosePrice.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET underlyingSettlementDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~underlyingSettlementDate.ok THEN Fail ELSE
    LET underlyingMaturityDate == ReadBytes(underlyingSettlementDate.rest, 4) IN IF ~underlyingMaturityDate.ok THEN Fail ELSE
    LET relatedTradeId == ReadBytes(underlyingMaturityDate.rest, 4) IN IF ~relatedTradeId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(relatedTradeId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET relatedTradeQuantity == ReadBytes(relatedMarketSegmentId.rest, 4) IN IF ~relatedTradeQuantity.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedTradeQuantity.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(trdType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(productComplex.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(tradeReportType.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET noSideAllocs == ReadUIntBE(tradePublishIndicator.rest, 1) IN IF ~noSideAllocs.ok THEN Fail ELSE
    LET noEvents == ReadUIntBE(noSideAllocs.rest, 1) IN IF ~noEvents.ok THEN Fail ELSE
    LET noInstrAttrib == ReadUIntBE(noEvents.rest, 1) IN IF ~noInstrAttrib.ok THEN Fail ELSE
    LET noUnderlyingStips == ReadUIntBE(noInstrAttrib.rest, 1) IN IF ~noUnderlyingStips.ok THEN Fail ELSE
    LET partyIdSettlementLocation == ReadBytes(noUnderlyingStips.rest, 1) IN IF ~partyIdSettlementLocation.ok THEN Fail ELSE
    LET hedgeType == ReadBytes(partyIdSettlementLocation.rest, 1) IN IF ~hedgeType.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(hedgeType.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET underlyingSecurityId == ReadBytes(tradeReportId.rest, 12) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET underlyingSecurityDesc == ReadBytes(underlyingSecurityId.rest, 30) IN IF ~underlyingSecurityDesc.ok THEN Fail ELSE
    LET underlyingCurrency == ReadBytes(underlyingSecurityDesc.rest, 3) IN IF ~underlyingCurrency.ok THEN Fail ELSE
    LET underlyingIssuer == ReadBytes(underlyingCurrency.rest, 30) IN IF ~underlyingIssuer.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(underlyingIssuer.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    LET sideAllocGrpComp == ReadSideAllocGrpCompList(pad2v2.rest, noSideAllocs.value) IN IF ~sideAllocGrpComp.ok THEN Fail ELSE
    LET instrumentEventGrpComp == ReadInstrumentEventGrpCompList(sideAllocGrpComp.rest, noEvents.value) IN IF ~instrumentEventGrpComp.ok THEN Fail ELSE
    LET instrumentAttributeGrpComp == ReadInstrumentAttributeGrpCompList(instrumentEventGrpComp.rest, noInstrAttrib.value) IN IF ~instrumentAttributeGrpComp.ok THEN Fail ELSE
    LET underlyingStipGrpComp == ReadUnderlyingStipGrpCompList(instrumentAttributeGrpComp.rest, noUnderlyingStips.value) IN IF ~underlyingStipGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId               |-> networkMsgId.value,
         pad2                       |-> pad2.value,
         requestHeaderComp          |-> requestHeaderComp.value,
         securityId                 |-> securityId.value,
         lastPx                     |-> lastPx.value,
         transBkdTime               |-> transBkdTime.value,
         underlyingPx               |-> underlyingPx.value,
         underlyingQty              |-> underlyingQty.value,
         relatedClosePrice          |-> relatedClosePrice.value,
         marketSegmentId            |-> marketSegmentId.value,
         underlyingSettlementDate   |-> underlyingSettlementDate.value,
         underlyingMaturityDate     |-> underlyingMaturityDate.value,
         relatedTradeId             |-> relatedTradeId.value,
         relatedMarketSegmentId     |-> relatedMarketSegmentId.value,
         relatedTradeQuantity       |-> relatedTradeQuantity.value,
         trdType                    |-> trdType.value,
         productComplex             |-> productComplex.value,
         tradeReportType            |-> tradeReportType.value,
         tradePublishIndicator      |-> tradePublishIndicator.value,
         partyIdSettlementLocation  |-> partyIdSettlementLocation.value,
         hedgeType                  |-> hedgeType.value,
         tradeReportText            |-> tradeReportText.value,
         tradeReportId              |-> tradeReportId.value,
         underlyingSecurityId       |-> underlyingSecurityId.value,
         underlyingSecurityDesc     |-> underlyingSecurityDesc.value,
         underlyingCurrency         |-> underlyingCurrency.value,
         underlyingIssuer           |-> underlyingIssuer.value,
         pad2v2                     |-> pad2v2.value,
         sideAllocGrpComp           |-> sideAllocGrpComp.value,
         instrumentEventGrpComp     |-> instrumentEventGrpComp.value,
         instrumentAttributeGrpComp |-> instrumentAttributeGrpComp.value,
         underlyingStipGrpComp      |-> underlyingStipGrpComp.value ], underlyingStipGrpComp.rest)

ZeroEnterTesTradeRequest ==
    [ networkMsgId               |-> [i \in 1 .. 8 |-> 0],
      pad2                       |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp          |-> ZeroRequestHeaderComp10,
      securityId                 |-> [i \in 1 .. 8 |-> 0],
      lastPx                     |-> [i \in 1 .. 8 |-> 0],
      transBkdTime               |-> [i \in 1 .. 8 |-> 0],
      underlyingPx               |-> [i \in 1 .. 8 |-> 0],
      underlyingQty              |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId            |-> [i \in 1 .. 4 |-> 0],
      underlyingSettlementDate   |-> [i \in 1 .. 4 |-> 0],
      underlyingMaturityDate     |-> [i \in 1 .. 4 |-> 0],
      relatedTradeId             |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId     |-> [i \in 1 .. 4 |-> 0],
      relatedTradeQuantity       |-> [i \in 1 .. 4 |-> 0],
      trdType                    |-> [i \in 1 .. 2 |-> 0],
      productComplex             |-> [i \in 1 .. 1 |-> 0],
      tradeReportType            |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator      |-> [i \in 1 .. 1 |-> 0],
      partyIdSettlementLocation  |-> [i \in 1 .. 1 |-> 0],
      hedgeType                  |-> [i \in 1 .. 1 |-> 0],
      tradeReportText            |-> [i \in 1 .. 20 |-> 0],
      tradeReportId              |-> [i \in 1 .. 20 |-> 0],
      underlyingSecurityId       |-> [i \in 1 .. 12 |-> 0],
      underlyingSecurityDesc     |-> [i \in 1 .. 30 |-> 0],
      underlyingCurrency         |-> [i \in 1 .. 3 |-> 0],
      underlyingIssuer           |-> [i \in 1 .. 30 |-> 0],
      pad2v2                     |-> [i \in 1 .. 2 |-> 0],
      sideAllocGrpComp           |-> << >>,
      instrumentEventGrpComp     |-> << >>,
      instrumentAttributeGrpComp |-> << >>,
      underlyingStipGrpComp      |-> << >> ]

(* Enter Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedEnterTesTradeRequest ==
    { ZeroEnterTesTradeRequest }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp10 }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingPx = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingQty = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingSettlementDate = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingMaturityDate = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.relatedTradeId = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.relatedTradeQuantity = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.partyIdSettlementLocation = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.hedgeType = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingSecurityId = one] : one \in Sample(12) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingSecurityDesc = one] : one \in Sample(30) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingIssuer = one] : one \in Sample(30) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.sideAllocGrpComp = one] : one \in SampleLists(OneSideAllocGrpComp) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.instrumentEventGrpComp = one] : one \in SampleLists(OneInstrumentEventGrpComp) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.instrumentAttributeGrpComp = one] : one \in SampleLists(OneInstrumentAttributeGrpComp) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.underlyingStipGrpComp = one] : one \in SampleLists(OneUnderlyingStipGrpComp) }

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
(* Gateway Request: 90 bytes                                               *)
(***************************************************************************)

GatewayRequest ==
    [ networkMsgId         : Sample(8),
      pad2                 : Sample(2),
      requestHeaderComp    : RequestHeaderComp11,
      partyIdSessionId     : Sample(4),
      defaultCstmApplVerId : Sample(30),
      password             : Sample(32),
      pad6                 : Sample(6) ]

EncodeGatewayRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp11(message.requestHeaderComp)
        \o message.partyIdSessionId
        \o message.defaultCstmApplVerId
        \o message.password
        \o message.pad6

DecodeGatewayRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp11(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp    |-> ZeroRequestHeaderComp11,
      partyIdSessionId     |-> [i \in 1 .. 4 |-> 0],
      defaultCstmApplVerId |-> [i \in 1 .. 30 |-> 0],
      password             |-> [i \in 1 .. 32 |-> 0],
      pad6                 |-> [i \in 1 .. 6 |-> 0] ]

(* Gateway Request at zero, then each field in turn at the values it is checked at *)
CheckedGatewayRequest ==
    { ZeroGatewayRequest }
        \cup { [ZeroGatewayRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroGatewayRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroGatewayRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp11 }
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
(* Inquire Enrichment Rule Id List Request: 34 bytes                       *)
(***************************************************************************)

InquireEnrichmentRuleIdListRequest ==
    [ networkMsgId        : Sample(8),
      pad2                : Sample(2),
      requestHeaderComp   : RequestHeaderComp12,
      lastEntityProcessed : Sample(16) ]

EncodeInquireEnrichmentRuleIdListRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp12(message.requestHeaderComp)
        \o message.lastEntityProcessed

DecodeInquireEnrichmentRuleIdListRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp12(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET lastEntityProcessed == ReadBytes(requestHeaderComp.rest, 16) IN IF ~lastEntityProcessed.ok THEN Fail ELSE
    Ok([ networkMsgId        |-> networkMsgId.value,
         pad2                |-> pad2.value,
         requestHeaderComp   |-> requestHeaderComp.value,
         lastEntityProcessed |-> lastEntityProcessed.value ], lastEntityProcessed.rest)

ZeroInquireEnrichmentRuleIdListRequest ==
    [ networkMsgId        |-> [i \in 1 .. 8 |-> 0],
      pad2                |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp   |-> ZeroRequestHeaderComp12,
      lastEntityProcessed |-> [i \in 1 .. 16 |-> 0] ]

(* Inquire Enrichment Rule Id List Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireEnrichmentRuleIdListRequest ==
    { ZeroInquireEnrichmentRuleIdListRequest }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp12 }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }

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
(* Inquire Mm Parameter Request: 26 bytes                                  *)
(***************************************************************************)

InquireMmParameterRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp13,
      marketSegmentId        : Sample(4),
      targetPartyIdSessionId : Sample(4) ]

EncodeInquireMmParameterRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp13(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId

DecodeInquireMmParameterRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp13(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         marketSegmentId        |-> marketSegmentId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value ], targetPartyIdSessionId.rest)

ZeroInquireMmParameterRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp13,
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Inquire Mm Parameter Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireMmParameterRequest ==
    { ZeroInquireMmParameterRequest }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp13 }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroInquireMmParameterRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }

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
(* Inquire Session List Request: 18 bytes                                  *)
(***************************************************************************)

InquireSessionListRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp14 ]

EncodeInquireSessionListRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp14(message.requestHeaderComp)

DecodeInquireSessionListRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp14(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroInquireSessionListRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp14 ]

(* Inquire Session List Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireSessionListRequest ==
    { ZeroInquireSessionListRequest }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp14 }

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
(* Inquire User Request: 34 bytes                                          *)
(***************************************************************************)

InquireUserRequest ==
    [ networkMsgId        : Sample(8),
      pad2                : Sample(2),
      requestHeaderComp   : RequestHeaderComp15,
      lastEntityProcessed : Sample(16) ]

EncodeInquireUserRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp15(message.requestHeaderComp)
        \o message.lastEntityProcessed

DecodeInquireUserRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp15(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET lastEntityProcessed == ReadBytes(requestHeaderComp.rest, 16) IN IF ~lastEntityProcessed.ok THEN Fail ELSE
    Ok([ networkMsgId        |-> networkMsgId.value,
         pad2                |-> pad2.value,
         requestHeaderComp   |-> requestHeaderComp.value,
         lastEntityProcessed |-> lastEntityProcessed.value ], lastEntityProcessed.rest)

ZeroInquireUserRequest ==
    [ networkMsgId        |-> [i \in 1 .. 8 |-> 0],
      pad2                |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp   |-> ZeroRequestHeaderComp15,
      lastEntityProcessed |-> [i \in 1 .. 16 |-> 0] ]

(* Inquire User Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireUserRequest ==
    { ZeroInquireUserRequest }
        \cup { [ZeroInquireUserRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireUserRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireUserRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp15 }
        \cup { [ZeroInquireUserRequest EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }

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
(* Logon Request: 274 bytes                                                *)
(***************************************************************************)

LogonRequest ==
    [ networkMsgId             : Sample(8),
      pad2                     : Sample(2),
      requestHeaderComp        : RequestHeaderComp16,
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
        \o EncodeRequestHeaderComp16(message.requestHeaderComp)
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
    LET requestHeaderComp == DecodeRequestHeaderComp16(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp        |-> ZeroRequestHeaderComp16,
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
        \cup { [ZeroLogonRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp16 }
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
(* Logout Request: 18 bytes                                                *)
(***************************************************************************)

LogoutRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp17 ]

EncodeLogoutRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp17(message.requestHeaderComp)

DecodeLogoutRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp17(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroLogoutRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp17 ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroLogoutRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogoutRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp17 }

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
(* Mm Parameter Definition Request: 58 bytes                               *)
(***************************************************************************)

MmParameterDefinitionRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp18,
      exposureDuration       : Sample(8),
      marketSegmentId        : Sample(4),
      targetPartyIdSessionId : Sample(4),
      cumQty                 : Sample(4),
      pctCount               : Sample(4),
      delta                  : Sample(4),
      vega                   : Sample(4),
      productComplex         : Sample(1),
      pad7                   : Sample(7) ]

EncodeMmParameterDefinitionRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp18(message.requestHeaderComp)
        \o message.exposureDuration
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.cumQty
        \o message.pctCount
        \o message.delta
        \o message.vega
        \o message.productComplex
        \o message.pad7

DecodeMmParameterDefinitionRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp18(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET exposureDuration == ReadBytes(requestHeaderComp.rest, 8) IN IF ~exposureDuration.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(exposureDuration.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET cumQty == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~cumQty.ok THEN Fail ELSE
    LET pctCount == ReadBytes(cumQty.rest, 4) IN IF ~pctCount.ok THEN Fail ELSE
    LET delta == ReadBytes(pctCount.rest, 4) IN IF ~delta.ok THEN Fail ELSE
    LET vega == ReadBytes(delta.rest, 4) IN IF ~vega.ok THEN Fail ELSE
    LET productComplex == ReadBytes(vega.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET pad7 == ReadBytes(productComplex.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         exposureDuration       |-> exposureDuration.value,
         marketSegmentId        |-> marketSegmentId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value,
         cumQty                 |-> cumQty.value,
         pctCount               |-> pctCount.value,
         delta                  |-> delta.value,
         vega                   |-> vega.value,
         productComplex         |-> productComplex.value,
         pad7                   |-> pad7.value ], pad7.rest)

ZeroMmParameterDefinitionRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp18,
      exposureDuration       |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0],
      cumQty                 |-> [i \in 1 .. 4 |-> 0],
      pctCount               |-> [i \in 1 .. 4 |-> 0],
      delta                  |-> [i \in 1 .. 4 |-> 0],
      vega                   |-> [i \in 1 .. 4 |-> 0],
      productComplex         |-> [i \in 1 .. 1 |-> 0],
      pad7                   |-> [i \in 1 .. 7 |-> 0] ]

(* Mm Parameter Definition Request at zero, then each field in turn at the values it is checked at *)
CheckedMmParameterDefinitionRequest ==
    { ZeroMmParameterDefinitionRequest }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp18 }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.exposureDuration = one] : one \in Sample(8) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.cumQty = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.pctCount = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.delta = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.vega = one] : one \in Sample(4) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroMmParameterDefinitionRequest EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Quote Entry Grp Comp: 32 bytes                                          *)
(***************************************************************************)

QuoteEntryGrpComp ==
    [ securityId : Sample(8),
      bidPx      : Sample(8),
      offerPx    : Sample(8),
      bidSize    : Sample(4),
      offerSize  : Sample(4) ]

EncodeQuoteEntryGrpComp(message) ==
    message.securityId
        \o message.bidPx
        \o message.offerPx
        \o message.bidSize
        \o message.offerSize

DecodeQuoteEntryGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(offerPx.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         bidPx      |-> bidPx.value,
         offerPx    |-> offerPx.value,
         bidSize    |-> bidSize.value,
         offerSize  |-> offerSize.value ], offerSize.rest)

ZeroQuoteEntryGrpComp ==
    [ securityId |-> [i \in 1 .. 8 |-> 0],
      bidPx      |-> [i \in 1 .. 8 |-> 0],
      offerPx    |-> [i \in 1 .. 8 |-> 0],
      bidSize    |-> [i \in 1 .. 4 |-> 0],
      offerSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Entry Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEntryGrpComp ==
    { ZeroQuoteEntryGrpComp }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.offerSize = one] : one \in Sample(4) }

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
      requestHeaderComp      : RequestHeaderComp19,
      quoteId                : Sample(8),
      complianceId           : Sample(8),
      marketSegmentId        : Sample(4),
      matchInstCrossId       : Sample(4),
      enrichmentRuleId       : Sample(2),
      priceValidityCheckType : Sample(1),
      quoteSizeType          : Sample(1),
      pad3                   : Sample(3),
      quoteEntryGrpComp      : SampleLists(OneQuoteEntryGrpComp) ]

EncodeMassQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp19(message.requestHeaderComp)
        \o message.quoteId
        \o message.complianceId
        \o message.marketSegmentId
        \o message.matchInstCrossId
        \o message.enrichmentRuleId
        \o message.priceValidityCheckType
        \o message.quoteSizeType
        \o EncodeUIntBE(Len(message.quoteEntryGrpComp), 1)
        \o message.pad3
        \o EncodeQuoteEntryGrpCompList(message.quoteEntryGrpComp)

DecodeMassQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp19(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(quoteId.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(marketSegmentId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(matchInstCrossId.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET quoteSizeType == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~quoteSizeType.ok THEN Fail ELSE
    LET noQuoteEntries == ReadUIntBE(quoteSizeType.rest, 1) IN IF ~noQuoteEntries.ok THEN Fail ELSE
    LET pad3 == ReadBytes(noQuoteEntries.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET quoteEntryGrpComp == ReadQuoteEntryGrpCompList(pad3.rest, noQuoteEntries.value) IN IF ~quoteEntryGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         quoteId                |-> quoteId.value,
         complianceId           |-> complianceId.value,
         marketSegmentId        |-> marketSegmentId.value,
         matchInstCrossId       |-> matchInstCrossId.value,
         enrichmentRuleId       |-> enrichmentRuleId.value,
         priceValidityCheckType |-> priceValidityCheckType.value,
         quoteSizeType          |-> quoteSizeType.value,
         pad3                   |-> pad3.value,
         quoteEntryGrpComp      |-> quoteEntryGrpComp.value ], quoteEntryGrpComp.rest)

ZeroMassQuoteRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp19,
      quoteId                |-> [i \in 1 .. 8 |-> 0],
      complianceId           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId       |-> [i \in 1 .. 4 |-> 0],
      enrichmentRuleId       |-> [i \in 1 .. 2 |-> 0],
      priceValidityCheckType |-> [i \in 1 .. 1 |-> 0],
      quoteSizeType          |-> [i \in 1 .. 1 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0],
      quoteEntryGrpComp      |-> << >> ]

(* Mass Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequest ==
    { ZeroMassQuoteRequest }
        \cup { [ZeroMassQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp19 }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteSizeType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteEntryGrpComp = one] : one \in SampleLists(OneQuoteEntryGrpComp) }

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
      requestHeaderComp           : RequestHeaderComp20,
      orderId                     : Sample(8),
      clOrdId                     : Sample(8),
      origClOrdId                 : Sample(8),
      securityId                  : Sample(8),
      price                       : Sample(8),
      complianceId                : Sample(8),
      marketSegmentId             : Sample(4),
      orderQty                    : Sample(4),
      expireDate                  : Sample(4),
      matchInstCrossId            : Sample(4),
      targetPartyIdSessionId      : Sample(4),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      applSeqIndicator            : Sample(1),
      productComplex              : Sample(1),
      side                        : Sample(1),
      ordType                     : Sample(1),
      priceValidityCheckType      : Sample(1),
      execInst                    : Sample(1),
      timeInForce                 : Sample(1),
      tradingCapacity             : Sample(1),
      ownershipIndicator          : Sample(1),
      partyIdLocationId           : Sample(2),
      custOrderHandlingInst       : Sample(1),
      complianceText              : Sample(20),
      partyIdPositionAccount      : Sample(32),
      freeText1                   : Sample(12),
      freeText2                   : Sample(12),
      freeText3                   : Sample(12),
      pad2v2                      : Sample(2),
      legOrdGrpComp               : SampleLists(OneLegOrdGrpComp) ]

EncodeModifyOrderComplexRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp20(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.price
        \o message.complianceId
        \o message.marketSegmentId
        \o message.orderQty
        \o message.expireDate
        \o message.matchInstCrossId
        \o message.targetPartyIdSessionId
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.applSeqIndicator
        \o message.productComplex
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.execInst
        \o message.timeInForce
        \o message.tradingCapacity
        \o message.ownershipIndicator
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.partyIdPositionAccount
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o EncodeUIntBE(Len(message.legOrdGrpComp), 1)
        \o message.pad2v2
        \o EncodeLegOrdGrpCompList(message.legOrdGrpComp)

DecodeModifyOrderComplexRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp20(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET complianceId == ReadBytes(price.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(orderQty.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(expireDate.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(matchInstCrossId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(targetPartyIdSessionId.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET productComplex == ReadBytes(applSeqIndicator.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET side == ReadBytes(productComplex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET execInst == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(execInst.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(timeInForce.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET ownershipIndicator == ReadBytes(tradingCapacity.rest, 1) IN IF ~ownershipIndicator.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(ownershipIndicator.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(complianceText.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyIdPositionAccount.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
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
         complianceId                |-> complianceId.value,
         marketSegmentId             |-> marketSegmentId.value,
         orderQty                    |-> orderQty.value,
         expireDate                  |-> expireDate.value,
         matchInstCrossId            |-> matchInstCrossId.value,
         targetPartyIdSessionId      |-> targetPartyIdSessionId.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         applSeqIndicator            |-> applSeqIndicator.value,
         productComplex              |-> productComplex.value,
         side                        |-> side.value,
         ordType                     |-> ordType.value,
         priceValidityCheckType      |-> priceValidityCheckType.value,
         execInst                    |-> execInst.value,
         timeInForce                 |-> timeInForce.value,
         tradingCapacity             |-> tradingCapacity.value,
         ownershipIndicator          |-> ownershipIndicator.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         complianceText              |-> complianceText.value,
         partyIdPositionAccount      |-> partyIdPositionAccount.value,
         freeText1                   |-> freeText1.value,
         freeText2                   |-> freeText2.value,
         freeText3                   |-> freeText3.value,
         pad2v2                      |-> pad2v2.value,
         legOrdGrpComp               |-> legOrdGrpComp.value ], legOrdGrpComp.rest)

ZeroModifyOrderComplexRequest ==
    [ networkMsgId                |-> [i \in 1 .. 8 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp           |-> ZeroRequestHeaderComp20,
      orderId                     |-> [i \in 1 .. 8 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                 |-> [i \in 1 .. 8 |-> 0],
      securityId                  |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      complianceId                |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      expireDate                  |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId            |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId      |-> [i \in 1 .. 4 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      applSeqIndicator            |-> [i \in 1 .. 1 |-> 0],
      productComplex              |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      ordType                     |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType      |-> [i \in 1 .. 1 |-> 0],
      execInst                    |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      ownershipIndicator          |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      complianceText              |-> [i \in 1 .. 20 |-> 0],
      partyIdPositionAccount      |-> [i \in 1 .. 32 |-> 0],
      freeText1                   |-> [i \in 1 .. 12 |-> 0],
      freeText2                   |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      pad2v2                      |-> [i \in 1 .. 2 |-> 0],
      legOrdGrpComp               |-> << >> ]

(* Modify Order Complex Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderComplexRequest ==
    { ZeroModifyOrderComplexRequest }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp20 }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.ownershipIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderComplexRequest EXCEPT !.legOrdGrpComp = one] : one \in SampleLists(OneLegOrdGrpComp) }

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
(* Modify Order Single Request: 218 bytes                                  *)
(***************************************************************************)

ModifyOrderSingleRequest ==
    [ networkMsgId                : Sample(8),
      pad2                        : Sample(2),
      requestHeaderComp           : RequestHeaderComp21,
      orderId                     : Sample(8),
      clOrdId                     : Sample(8),
      origClOrdId                 : Sample(8),
      price                       : Sample(8),
      stopPx                      : Sample(8),
      complianceId                : Sample(8),
      orderQty                    : Sample(4),
      expireDate                  : Sample(4),
      marketSegmentId             : Sample(4),
      simpleSecurityId            : Sample(4),
      matchInstCrossId            : Sample(4),
      targetPartyIdSessionId      : Sample(4),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      applSeqIndicator            : Sample(1),
      side                        : Sample(1),
      ordType                     : Sample(1),
      priceValidityCheckType      : Sample(1),
      timeInForce                 : Sample(1),
      execInst                    : Sample(1),
      tradingSessionSubId         : Sample(1),
      tradingCapacity             : Sample(1),
      account                     : Sample(2),
      partyIdPositionAccount      : Sample(32),
      positionEffect              : Sample(1),
      ownershipIndicator          : Sample(1),
      partyIdLocationId           : Sample(2),
      custOrderHandlingInst       : Sample(1),
      complianceText              : Sample(20),
      freeText1                   : Sample(12),
      freeText2                   : Sample(12),
      freeText3                   : Sample(12),
      pad4                        : Sample(4) ]

EncodeModifyOrderSingleRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp21(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.price
        \o message.stopPx
        \o message.complianceId
        \o message.orderQty
        \o message.expireDate
        \o message.marketSegmentId
        \o message.simpleSecurityId
        \o message.matchInstCrossId
        \o message.targetPartyIdSessionId
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.applSeqIndicator
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.timeInForce
        \o message.execInst
        \o message.tradingSessionSubId
        \o message.tradingCapacity
        \o message.account
        \o message.partyIdPositionAccount
        \o message.positionEffect
        \o message.ownershipIndicator
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.pad4

DecodeModifyOrderSingleRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp21(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET complianceId == ReadBytes(stopPx.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(complianceId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(orderQty.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(expireDate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(marketSegmentId.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(simpleSecurityId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(matchInstCrossId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(targetPartyIdSessionId.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(applSeqIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(execInst.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET account == ReadBytes(tradingCapacity.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(account.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(partyIdPositionAccount.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET ownershipIndicator == ReadBytes(positionEffect.rest, 1) IN IF ~ownershipIndicator.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(ownershipIndicator.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(complianceText.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET pad4 == ReadBytes(freeText3.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId                |-> networkMsgId.value,
         pad2                        |-> pad2.value,
         requestHeaderComp           |-> requestHeaderComp.value,
         orderId                     |-> orderId.value,
         clOrdId                     |-> clOrdId.value,
         origClOrdId                 |-> origClOrdId.value,
         price                       |-> price.value,
         stopPx                      |-> stopPx.value,
         complianceId                |-> complianceId.value,
         orderQty                    |-> orderQty.value,
         expireDate                  |-> expireDate.value,
         marketSegmentId             |-> marketSegmentId.value,
         simpleSecurityId            |-> simpleSecurityId.value,
         matchInstCrossId            |-> matchInstCrossId.value,
         targetPartyIdSessionId      |-> targetPartyIdSessionId.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         applSeqIndicator            |-> applSeqIndicator.value,
         side                        |-> side.value,
         ordType                     |-> ordType.value,
         priceValidityCheckType      |-> priceValidityCheckType.value,
         timeInForce                 |-> timeInForce.value,
         execInst                    |-> execInst.value,
         tradingSessionSubId         |-> tradingSessionSubId.value,
         tradingCapacity             |-> tradingCapacity.value,
         account                     |-> account.value,
         partyIdPositionAccount      |-> partyIdPositionAccount.value,
         positionEffect              |-> positionEffect.value,
         ownershipIndicator          |-> ownershipIndicator.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         complianceText              |-> complianceText.value,
         freeText1                   |-> freeText1.value,
         freeText2                   |-> freeText2.value,
         freeText3                   |-> freeText3.value,
         pad4                        |-> pad4.value ], pad4.rest)

ZeroModifyOrderSingleRequest ==
    [ networkMsgId                |-> [i \in 1 .. 8 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp           |-> ZeroRequestHeaderComp21,
      orderId                     |-> [i \in 1 .. 8 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                 |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      stopPx                      |-> [i \in 1 .. 8 |-> 0],
      complianceId                |-> [i \in 1 .. 8 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      expireDate                  |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId            |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId            |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId      |-> [i \in 1 .. 4 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      applSeqIndicator            |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      ordType                     |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType      |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      execInst                    |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId         |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      account                     |-> [i \in 1 .. 2 |-> 0],
      partyIdPositionAccount      |-> [i \in 1 .. 32 |-> 0],
      positionEffect              |-> [i \in 1 .. 1 |-> 0],
      ownershipIndicator          |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      complianceText              |-> [i \in 1 .. 20 |-> 0],
      freeText1                   |-> [i \in 1 .. 12 |-> 0],
      freeText2                   |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      pad4                        |-> [i \in 1 .. 4 |-> 0] ]

(* Modify Order Single Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderSingleRequest ==
    { ZeroModifyOrderSingleRequest }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp21 }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.ownershipIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

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
(* Modify Order Single Short Request: 74 bytes                             *)
(***************************************************************************)

ModifyOrderSingleShortRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp22,
      clOrdId                : Sample(8),
      origClOrdId            : Sample(8),
      price                  : Sample(8),
      complianceId           : Sample(8),
      orderQty               : Sample(4),
      simpleSecurityId       : Sample(4),
      matchInstCrossId       : Sample(4),
      enrichmentRuleId       : Sample(2),
      side                   : Sample(1),
      priceValidityCheckType : Sample(1),
      timeInForce            : Sample(1),
      execInst               : Sample(1),
      tradingCapacity        : Sample(1),
      pad5                   : Sample(5) ]

EncodeModifyOrderSingleShortRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp22(message.requestHeaderComp)
        \o message.clOrdId
        \o message.origClOrdId
        \o message.price
        \o message.complianceId
        \o message.orderQty
        \o message.simpleSecurityId
        \o message.matchInstCrossId
        \o message.enrichmentRuleId
        \o message.side
        \o message.priceValidityCheckType
        \o message.timeInForce
        \o message.execInst
        \o message.tradingCapacity
        \o message.pad5

DecodeModifyOrderSingleShortRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp22(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET price == ReadBytes(origClOrdId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET complianceId == ReadBytes(price.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(complianceId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(orderQty.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(simpleSecurityId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(matchInstCrossId.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET side == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(side.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET pad5 == ReadBytes(tradingCapacity.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         clOrdId                |-> clOrdId.value,
         origClOrdId            |-> origClOrdId.value,
         price                  |-> price.value,
         complianceId           |-> complianceId.value,
         orderQty               |-> orderQty.value,
         simpleSecurityId       |-> simpleSecurityId.value,
         matchInstCrossId       |-> matchInstCrossId.value,
         enrichmentRuleId       |-> enrichmentRuleId.value,
         side                   |-> side.value,
         priceValidityCheckType |-> priceValidityCheckType.value,
         timeInForce            |-> timeInForce.value,
         execInst               |-> execInst.value,
         tradingCapacity        |-> tradingCapacity.value,
         pad5                   |-> pad5.value ], pad5.rest)

ZeroModifyOrderSingleShortRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp22,
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      origClOrdId            |-> [i \in 1 .. 8 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      complianceId           |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId       |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId       |-> [i \in 1 .. 4 |-> 0],
      enrichmentRuleId       |-> [i \in 1 .. 2 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType |-> [i \in 1 .. 1 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity        |-> [i \in 1 .. 1 |-> 0],
      pad5                   |-> [i \in 1 .. 5 |-> 0] ]

(* Modify Order Single Short Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderSingleShortRequest ==
    { ZeroModifyOrderSingleShortRequest }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp22 }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.pad5 = one] : one \in Sample(5) }

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
(* Side Alloc Grp Comp: 24 bytes                                           *)
(***************************************************************************)

SideAllocGrpComp2 ==
    [ individualAllocId    : Sample(4),
      allocQty             : Sample(4),
      side                 : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeSideAllocGrpComp2(message) ==
    message.individualAllocId
        \o message.allocQty
        \o message.side
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeSideAllocGrpComp2(bytes) ==
    LET individualAllocId == ReadBytes(bytes, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET allocQty == ReadBytes(individualAllocId.rest, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET side == ReadBytes(allocQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ individualAllocId    |-> individualAllocId.value,
         allocQty             |-> allocQty.value,
         side                 |-> side.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroSideAllocGrpComp2 ==
    [ individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      allocQty             |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideAllocGrpComp2 ==
    { ZeroSideAllocGrpComp2 }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.pad4 = one] : one \in Sample(4) }

(* A run of Side Alloc Grp Comp, written one after another *)
RECURSIVE EncodeSideAllocGrpComp2List(_)
EncodeSideAllocGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSideAllocGrpComp2(Head(messages)) \o EncodeSideAllocGrpComp2List(Tail(messages))

(* As many Side Alloc Grp Comp as the field that counts them says *)
RECURSIVE ReadSideAllocGrpComp2List(_, _)
ReadSideAllocGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSideAllocGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSideAllocGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Side Alloc Grp Comp of each kind, for the lists that carry them *)
OneSideAllocGrpComp2 == { ZeroSideAllocGrpComp2 }

(***************************************************************************)
(* Modify Tes Trade Request                                                *)
(***************************************************************************)

ModifyTesTradeRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp23,
      lastPx                 : Sample(8),
      transBkdTime           : Sample(8),
      marketSegmentId        : Sample(4),
      packageId              : Sample(4),
      tesExecId              : Sample(4),
      relatedMarketSegmentId : Sample(4),
      trdType                : Sample(2),
      tradeReportType        : Sample(1),
      tradePublishIndicator  : Sample(1),
      tradeReportText        : Sample(20),
      tradeReportId          : Sample(20),
      pad3                   : Sample(3),
      sideAllocGrpComp       : SampleLists(OneSideAllocGrpComp2) ]

EncodeModifyTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp23(message.requestHeaderComp)
        \o message.lastPx
        \o message.transBkdTime
        \o message.marketSegmentId
        \o message.packageId
        \o message.tesExecId
        \o message.relatedMarketSegmentId
        \o message.trdType
        \o message.tradeReportType
        \o message.tradePublishIndicator
        \o EncodeUIntBE(Len(message.sideAllocGrpComp), 1)
        \o message.tradeReportText
        \o message.tradeReportId
        \o message.pad3
        \o EncodeSideAllocGrpComp2List(message.sideAllocGrpComp)

DecodeModifyTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp23(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET lastPx == ReadBytes(requestHeaderComp.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(transBkdTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET packageId == ReadBytes(marketSegmentId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(packageId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(tesExecId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedMarketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(tradeReportType.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET noSideAllocs == ReadUIntBE(tradePublishIndicator.rest, 1) IN IF ~noSideAllocs.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(noSideAllocs.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad3 == ReadBytes(tradeReportId.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    LET sideAllocGrpComp == ReadSideAllocGrpComp2List(pad3.rest, noSideAllocs.value) IN IF ~sideAllocGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         lastPx                 |-> lastPx.value,
         transBkdTime           |-> transBkdTime.value,
         marketSegmentId        |-> marketSegmentId.value,
         packageId              |-> packageId.value,
         tesExecId              |-> tesExecId.value,
         relatedMarketSegmentId |-> relatedMarketSegmentId.value,
         trdType                |-> trdType.value,
         tradeReportType        |-> tradeReportType.value,
         tradePublishIndicator  |-> tradePublishIndicator.value,
         tradeReportText        |-> tradeReportText.value,
         tradeReportId          |-> tradeReportId.value,
         pad3                   |-> pad3.value,
         sideAllocGrpComp       |-> sideAllocGrpComp.value ], sideAllocGrpComp.rest)

ZeroModifyTesTradeRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp23,
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      transBkdTime           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      packageId              |-> [i \in 1 .. 4 |-> 0],
      tesExecId              |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId |-> [i \in 1 .. 4 |-> 0],
      trdType                |-> [i \in 1 .. 2 |-> 0],
      tradeReportType        |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator  |-> [i \in 1 .. 1 |-> 0],
      tradeReportText        |-> [i \in 1 .. 20 |-> 0],
      tradeReportId          |-> [i \in 1 .. 20 |-> 0],
      pad3                   |-> [i \in 1 .. 3 |-> 0],
      sideAllocGrpComp       |-> << >> ]

(* Modify Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyTesTradeRequest ==
    { ZeroModifyTesTradeRequest }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp23 }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.pad3 = one] : one \in Sample(3) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.sideAllocGrpComp = one] : one \in SampleLists(OneSideAllocGrpComp2) }

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
      requestHeaderComp           : RequestHeaderComp24,
      clOrdId                     : Sample(8),
      securityId                  : Sample(8),
      price                       : Sample(8),
      complianceId                : Sample(8),
      marketSegmentId             : Sample(4),
      orderQty                    : Sample(4),
      expireDate                  : Sample(4),
      matchInstCrossId            : Sample(4),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      applSeqIndicator            : Sample(1),
      productComplex              : Sample(1),
      side                        : Sample(1),
      ordType                     : Sample(1),
      priceValidityCheckType      : Sample(1),
      execInst                    : Sample(1),
      timeInForce                 : Sample(1),
      tradingCapacity             : Sample(1),
      partyIdLocationId           : Sample(2),
      complianceText              : Sample(20),
      custOrderHandlingInst       : Sample(1),
      partyIdPositionAccount      : Sample(32),
      freeText1                   : Sample(12),
      freeText2                   : Sample(12),
      freeText3                   : Sample(12),
      pad7                        : Sample(7),
      legOrdGrpComp               : SampleLists(OneLegOrdGrpComp2) ]

EncodeNewOrderComplexRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp24(message.requestHeaderComp)
        \o message.clOrdId
        \o message.securityId
        \o message.price
        \o message.complianceId
        \o message.marketSegmentId
        \o message.orderQty
        \o message.expireDate
        \o message.matchInstCrossId
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.applSeqIndicator
        \o message.productComplex
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.execInst
        \o message.timeInForce
        \o message.tradingCapacity
        \o message.partyIdLocationId
        \o message.complianceText
        \o message.custOrderHandlingInst
        \o message.partyIdPositionAccount
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o EncodeUIntBE(Len(message.legOrdGrpComp), 1)
        \o message.pad7
        \o EncodeLegOrdGrpComp2List(message.legOrdGrpComp)

DecodeNewOrderComplexRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp24(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET complianceId == ReadBytes(price.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(orderQty.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(expireDate.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(matchInstCrossId.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET productComplex == ReadBytes(applSeqIndicator.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET side == ReadBytes(productComplex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET execInst == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(execInst.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(timeInForce.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(tradingCapacity.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET complianceText == ReadBytes(partyIdLocationId.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(complianceText.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(custOrderHandlingInst.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyIdPositionAccount.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(freeText3.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET pad7 == ReadBytes(noLegs.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET legOrdGrpComp == ReadLegOrdGrpComp2List(pad7.rest, noLegs.value) IN IF ~legOrdGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                |-> networkMsgId.value,
         pad2                        |-> pad2.value,
         requestHeaderComp           |-> requestHeaderComp.value,
         clOrdId                     |-> clOrdId.value,
         securityId                  |-> securityId.value,
         price                       |-> price.value,
         complianceId                |-> complianceId.value,
         marketSegmentId             |-> marketSegmentId.value,
         orderQty                    |-> orderQty.value,
         expireDate                  |-> expireDate.value,
         matchInstCrossId            |-> matchInstCrossId.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         applSeqIndicator            |-> applSeqIndicator.value,
         productComplex              |-> productComplex.value,
         side                        |-> side.value,
         ordType                     |-> ordType.value,
         priceValidityCheckType      |-> priceValidityCheckType.value,
         execInst                    |-> execInst.value,
         timeInForce                 |-> timeInForce.value,
         tradingCapacity             |-> tradingCapacity.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         complianceText              |-> complianceText.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         partyIdPositionAccount      |-> partyIdPositionAccount.value,
         freeText1                   |-> freeText1.value,
         freeText2                   |-> freeText2.value,
         freeText3                   |-> freeText3.value,
         pad7                        |-> pad7.value,
         legOrdGrpComp               |-> legOrdGrpComp.value ], legOrdGrpComp.rest)

ZeroNewOrderComplexRequest ==
    [ networkMsgId                |-> [i \in 1 .. 8 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp           |-> ZeroRequestHeaderComp24,
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      securityId                  |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      complianceId                |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      expireDate                  |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId            |-> [i \in 1 .. 4 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      applSeqIndicator            |-> [i \in 1 .. 1 |-> 0],
      productComplex              |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      ordType                     |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType      |-> [i \in 1 .. 1 |-> 0],
      execInst                    |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      complianceText              |-> [i \in 1 .. 20 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      partyIdPositionAccount      |-> [i \in 1 .. 32 |-> 0],
      freeText1                   |-> [i \in 1 .. 12 |-> 0],
      freeText2                   |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      pad7                        |-> [i \in 1 .. 7 |-> 0],
      legOrdGrpComp               |-> << >> ]

(* New Order Complex Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderComplexRequest ==
    { ZeroNewOrderComplexRequest }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp24 }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroNewOrderComplexRequest EXCEPT !.legOrdGrpComp = one] : one \in SampleLists(OneLegOrdGrpComp2) }

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
(* New Order Single Request: 194 bytes                                     *)
(***************************************************************************)

NewOrderSingleRequest ==
    [ networkMsgId                : Sample(8),
      pad2                        : Sample(2),
      requestHeaderComp           : RequestHeaderComp25,
      price                       : Sample(8),
      stopPx                      : Sample(8),
      clOrdId                     : Sample(8),
      complianceId                : Sample(8),
      orderQty                    : Sample(4),
      expireDate                  : Sample(4),
      marketSegmentId             : Sample(4),
      simpleSecurityId            : Sample(4),
      matchInstCrossId            : Sample(4),
      partyIdTakeUpTradingFirm    : Sample(5),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      applSeqIndicator            : Sample(1),
      side                        : Sample(1),
      ordType                     : Sample(1),
      priceValidityCheckType      : Sample(1),
      timeInForce                 : Sample(1),
      execInst                    : Sample(1),
      tradingSessionSubId         : Sample(1),
      tradingCapacity             : Sample(1),
      account                     : Sample(2),
      partyIdPositionAccount      : Sample(32),
      positionEffect              : Sample(1),
      partyIdLocationId           : Sample(2),
      custOrderHandlingInst       : Sample(1),
      complianceText              : Sample(20),
      freeText1                   : Sample(12),
      freeText2                   : Sample(12),
      freeText3                   : Sample(12),
      pad1                        : Sample(1) ]

EncodeNewOrderSingleRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp25(message.requestHeaderComp)
        \o message.price
        \o message.stopPx
        \o message.clOrdId
        \o message.complianceId
        \o message.orderQty
        \o message.expireDate
        \o message.marketSegmentId
        \o message.simpleSecurityId
        \o message.matchInstCrossId
        \o message.partyIdTakeUpTradingFirm
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.applSeqIndicator
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.timeInForce
        \o message.execInst
        \o message.tradingSessionSubId
        \o message.tradingCapacity
        \o message.account
        \o message.partyIdPositionAccount
        \o message.positionEffect
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.pad1

DecodeNewOrderSingleRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp25(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET price == ReadBytes(requestHeaderComp.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET stopPx == ReadBytes(price.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(stopPx.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(clOrdId.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(complianceId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(orderQty.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(expireDate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(marketSegmentId.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(simpleSecurityId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(matchInstCrossId.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(partyIdTakeUpTradingFirm.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(partyIdBeneficiary.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(applSeqIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(execInst.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET account == ReadBytes(tradingCapacity.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(account.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(partyIdPositionAccount.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(positionEffect.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(complianceText.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET pad1 == ReadBytes(freeText3.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId                |-> networkMsgId.value,
         pad2                        |-> pad2.value,
         requestHeaderComp           |-> requestHeaderComp.value,
         price                       |-> price.value,
         stopPx                      |-> stopPx.value,
         clOrdId                     |-> clOrdId.value,
         complianceId                |-> complianceId.value,
         orderQty                    |-> orderQty.value,
         expireDate                  |-> expireDate.value,
         marketSegmentId             |-> marketSegmentId.value,
         simpleSecurityId            |-> simpleSecurityId.value,
         matchInstCrossId            |-> matchInstCrossId.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         applSeqIndicator            |-> applSeqIndicator.value,
         side                        |-> side.value,
         ordType                     |-> ordType.value,
         priceValidityCheckType      |-> priceValidityCheckType.value,
         timeInForce                 |-> timeInForce.value,
         execInst                    |-> execInst.value,
         tradingSessionSubId         |-> tradingSessionSubId.value,
         tradingCapacity             |-> tradingCapacity.value,
         account                     |-> account.value,
         partyIdPositionAccount      |-> partyIdPositionAccount.value,
         positionEffect              |-> positionEffect.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         complianceText              |-> complianceText.value,
         freeText1                   |-> freeText1.value,
         freeText2                   |-> freeText2.value,
         freeText3                   |-> freeText3.value,
         pad1                        |-> pad1.value ], pad1.rest)

ZeroNewOrderSingleRequest ==
    [ networkMsgId                |-> [i \in 1 .. 8 |-> 0],
      pad2                        |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp           |-> ZeroRequestHeaderComp25,
      price                       |-> [i \in 1 .. 8 |-> 0],
      stopPx                      |-> [i \in 1 .. 8 |-> 0],
      clOrdId                     |-> [i \in 1 .. 8 |-> 0],
      complianceId                |-> [i \in 1 .. 8 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      expireDate                  |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId            |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId            |-> [i \in 1 .. 4 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      applSeqIndicator            |-> [i \in 1 .. 1 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      ordType                     |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType      |-> [i \in 1 .. 1 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      execInst                    |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId         |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      account                     |-> [i \in 1 .. 2 |-> 0],
      partyIdPositionAccount      |-> [i \in 1 .. 32 |-> 0],
      positionEffect              |-> [i \in 1 .. 1 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      complianceText              |-> [i \in 1 .. 20 |-> 0],
      freeText1                   |-> [i \in 1 .. 12 |-> 0],
      freeText2                   |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      pad1                        |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Single Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleRequest ==
    { ZeroNewOrderSingleRequest }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp25 }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

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
(* New Order Single Short Request: 66 bytes                                *)
(***************************************************************************)

NewOrderSingleShortRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp26,
      price                  : Sample(8),
      clOrdId                : Sample(8),
      complianceId           : Sample(8),
      orderQty               : Sample(4),
      simpleSecurityId       : Sample(4),
      matchInstCrossId       : Sample(4),
      enrichmentRuleId       : Sample(2),
      side                   : Sample(1),
      priceValidityCheckType : Sample(1),
      timeInForce            : Sample(1),
      execInst               : Sample(1),
      tradingCapacity        : Sample(1),
      pad5                   : Sample(5) ]

EncodeNewOrderSingleShortRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp26(message.requestHeaderComp)
        \o message.price
        \o message.clOrdId
        \o message.complianceId
        \o message.orderQty
        \o message.simpleSecurityId
        \o message.matchInstCrossId
        \o message.enrichmentRuleId
        \o message.side
        \o message.priceValidityCheckType
        \o message.timeInForce
        \o message.execInst
        \o message.tradingCapacity
        \o message.pad5

DecodeNewOrderSingleShortRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp26(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET price == ReadBytes(requestHeaderComp.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(price.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(clOrdId.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(complianceId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET simpleSecurityId == ReadBytes(orderQty.rest, 4) IN IF ~simpleSecurityId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(simpleSecurityId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(matchInstCrossId.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET side == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(side.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET pad5 == ReadBytes(tradingCapacity.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         price                  |-> price.value,
         clOrdId                |-> clOrdId.value,
         complianceId           |-> complianceId.value,
         orderQty               |-> orderQty.value,
         simpleSecurityId       |-> simpleSecurityId.value,
         matchInstCrossId       |-> matchInstCrossId.value,
         enrichmentRuleId       |-> enrichmentRuleId.value,
         side                   |-> side.value,
         priceValidityCheckType |-> priceValidityCheckType.value,
         timeInForce            |-> timeInForce.value,
         execInst               |-> execInst.value,
         tradingCapacity        |-> tradingCapacity.value,
         pad5                   |-> pad5.value ], pad5.rest)

ZeroNewOrderSingleShortRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp26,
      price                  |-> [i \in 1 .. 8 |-> 0],
      clOrdId                |-> [i \in 1 .. 8 |-> 0],
      complianceId           |-> [i \in 1 .. 8 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      simpleSecurityId       |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId       |-> [i \in 1 .. 4 |-> 0],
      enrichmentRuleId       |-> [i \in 1 .. 2 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType |-> [i \in 1 .. 1 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      execInst               |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity        |-> [i \in 1 .. 1 |-> 0],
      pad5                   |-> [i \in 1 .. 5 |-> 0] ]

(* New Order Single Short Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleShortRequest ==
    { ZeroNewOrderSingleShortRequest }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp26 }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.simpleSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp27 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp27(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp27(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp27 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp27 ==
    { ZeroRequestHeaderComp27 }
        \cup { [ZeroRequestHeaderComp27 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp27 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Activation Request: 42 bytes                                      *)
(***************************************************************************)

QuoteActivationRequest ==
    [ networkMsgId           : Sample(8),
      pad2                   : Sample(2),
      requestHeaderComp      : RequestHeaderComp27,
      complianceId           : Sample(8),
      marketSegmentId        : Sample(4),
      targetPartyIdSessionId : Sample(4),
      massActionType         : Sample(1),
      productComplex         : Sample(1),
      pad6                   : Sample(6) ]

EncodeQuoteActivationRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp27(message.requestHeaderComp)
        \o message.complianceId
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.massActionType
        \o message.productComplex
        \o message.pad6

DecodeQuoteActivationRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp27(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET complianceId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET massActionType == ReadBytes(targetPartyIdSessionId.rest, 1) IN IF ~massActionType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(massActionType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET pad6 == ReadBytes(productComplex.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId           |-> networkMsgId.value,
         pad2                   |-> pad2.value,
         requestHeaderComp      |-> requestHeaderComp.value,
         complianceId           |-> complianceId.value,
         marketSegmentId        |-> marketSegmentId.value,
         targetPartyIdSessionId |-> targetPartyIdSessionId.value,
         massActionType         |-> massActionType.value,
         productComplex         |-> productComplex.value,
         pad6                   |-> pad6.value ], pad6.rest)

ZeroQuoteActivationRequest ==
    [ networkMsgId           |-> [i \in 1 .. 8 |-> 0],
      pad2                   |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp      |-> ZeroRequestHeaderComp27,
      complianceId           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId |-> [i \in 1 .. 4 |-> 0],
      massActionType         |-> [i \in 1 .. 1 |-> 0],
      productComplex         |-> [i \in 1 .. 1 |-> 0],
      pad6                   |-> [i \in 1 .. 6 |-> 0] ]

(* Quote Activation Request at zero, then each field in turn at the values it is checked at *)
CheckedQuoteActivationRequest ==
    { ZeroQuoteActivationRequest }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp27 }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.massActionType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp28 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp28(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp28(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp28 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp28 ==
    { ZeroRequestHeaderComp28 }
        \cup { [ZeroRequestHeaderComp28 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp28 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Rfq Request: 66 bytes                                                   *)
(***************************************************************************)

RfqRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp28,
      securityId        : Sample(8),
      complianceId      : Sample(8),
      marketSegmentId   : Sample(4),
      orderQty          : Sample(4),
      side              : Sample(1),
      complianceText    : Sample(20),
      pad3              : Sample(3) ]

EncodeRfqRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp28(message.requestHeaderComp)
        \o message.securityId
        \o message.complianceId
        \o message.marketSegmentId
        \o message.orderQty
        \o message.side
        \o message.complianceText
        \o message.pad3

DecodeRfqRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp28(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET complianceId == ReadBytes(securityId.rest, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(complianceId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(marketSegmentId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET complianceText == ReadBytes(side.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad3 == ReadBytes(complianceText.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         securityId        |-> securityId.value,
         complianceId      |-> complianceId.value,
         marketSegmentId   |-> marketSegmentId.value,
         orderQty          |-> orderQty.value,
         side              |-> side.value,
         complianceText    |-> complianceText.value,
         pad3              |-> pad3.value ], pad3.rest)

ZeroRfqRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp28,
      securityId        |-> [i \in 1 .. 8 |-> 0],
      complianceId      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      orderQty          |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      complianceText    |-> [i \in 1 .. 20 |-> 0],
      pad3              |-> [i \in 1 .. 3 |-> 0] ]

(* Rfq Request at zero, then each field in turn at the values it is checked at *)
CheckedRfqRequest ==
    { ZeroRfqRequest }
        \cup { [ZeroRfqRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp28 }
        \cup { [ZeroRfqRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRfqRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroRfqRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRfqRequest EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroRfqRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp29 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp29(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp29(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp29 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp29 ==
    { ZeroRequestHeaderComp29 }
        \cup { [ZeroRequestHeaderComp29 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp29 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Me Message Request: 58 bytes                                 *)
(***************************************************************************)

RetransmitMeMessageRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp29,
      subscriptionScope : Sample(4),
      partitionId       : Sample(2),
      refApplId         : Sample(1),
      applBegMsgId      : Sample(16),
      applEndMsgId      : Sample(16),
      pad1              : Sample(1) ]

EncodeRetransmitMeMessageRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp29(message.requestHeaderComp)
        \o message.subscriptionScope
        \o message.partitionId
        \o message.refApplId
        \o message.applBegMsgId
        \o message.applEndMsgId
        \o message.pad1

DecodeRetransmitMeMessageRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp29(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp29,
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
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp29 }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.subscriptionScope = one] : one \in Sample(4) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.applBegMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.applEndMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp30 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp30(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp30(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp30 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp30 ==
    { ZeroRequestHeaderComp30 }
        \cup { [ZeroRequestHeaderComp30 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp30 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Request: 42 bytes                                            *)
(***************************************************************************)

RetransmitRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp30,
      applBegSeqNum     : Sample(8),
      applEndSeqNum     : Sample(8),
      partitionId       : Sample(2),
      refApplId         : Sample(1),
      pad5              : Sample(5) ]

EncodeRetransmitRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp30(message.requestHeaderComp)
        \o message.applBegSeqNum
        \o message.applEndSeqNum
        \o message.partitionId
        \o message.refApplId
        \o message.pad5

DecodeRetransmitRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp30(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET applBegSeqNum == ReadBytes(requestHeaderComp.rest, 8) IN IF ~applBegSeqNum.ok THEN Fail ELSE
    LET applEndSeqNum == ReadBytes(applBegSeqNum.rest, 8) IN IF ~applEndSeqNum.ok THEN Fail ELSE
    LET partitionId == ReadBytes(applEndSeqNum.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET refApplId == ReadBytes(partitionId.rest, 1) IN IF ~refApplId.ok THEN Fail ELSE
    LET pad5 == ReadBytes(refApplId.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         applBegSeqNum     |-> applBegSeqNum.value,
         applEndSeqNum     |-> applEndSeqNum.value,
         partitionId       |-> partitionId.value,
         refApplId         |-> refApplId.value,
         pad5              |-> pad5.value ], pad5.rest)

ZeroRetransmitRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp30,
      applBegSeqNum     |-> [i \in 1 .. 8 |-> 0],
      applEndSeqNum     |-> [i \in 1 .. 8 |-> 0],
      partitionId       |-> [i \in 1 .. 2 |-> 0],
      refApplId         |-> [i \in 1 .. 1 |-> 0],
      pad5              |-> [i \in 1 .. 5 |-> 0] ]

(* Retransmit Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRequest ==
    { ZeroRetransmitRequest }
        \cup { [ZeroRetransmitRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp30 }
        \cup { [ZeroRetransmitRequest EXCEPT !.applBegSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.applEndSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroRetransmitRequest EXCEPT !.pad5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp31 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp31(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp31(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp31 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp31 ==
    { ZeroRequestHeaderComp31 }
        \cup { [ZeroRequestHeaderComp31 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp31 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Subscribe Request: 26 bytes                                             *)
(***************************************************************************)

SubscribeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp31,
      subscriptionScope : Sample(4),
      refApplId         : Sample(1),
      pad3              : Sample(3) ]

EncodeSubscribeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp31(message.requestHeaderComp)
        \o message.subscriptionScope
        \o message.refApplId
        \o message.pad3

DecodeSubscribeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp31(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp31,
      subscriptionScope |-> [i \in 1 .. 4 |-> 0],
      refApplId         |-> [i \in 1 .. 1 |-> 0],
      pad3              |-> [i \in 1 .. 3 |-> 0] ]

(* Subscribe Request at zero, then each field in turn at the values it is checked at *)
CheckedSubscribeRequest ==
    { ZeroSubscribeRequest }
        \cup { [ZeroSubscribeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSubscribeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSubscribeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp31 }
        \cup { [ZeroSubscribeRequest EXCEPT !.subscriptionScope = one] : one \in Sample(4) }
        \cup { [ZeroSubscribeRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroSubscribeRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp32 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp32(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp32(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp32 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp32 ==
    { ZeroRequestHeaderComp32 }
        \cup { [ZeroRequestHeaderComp32 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp32 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Unsubscribe Request: 26 bytes                                           *)
(***************************************************************************)

UnsubscribeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp32,
      refApplSubId      : Sample(4),
      pad4              : Sample(4) ]

EncodeUnsubscribeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp32(message.requestHeaderComp)
        \o message.refApplSubId
        \o message.pad4

DecodeUnsubscribeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp32(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp32,
      refApplSubId      |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Unsubscribe Request at zero, then each field in turn at the values it is checked at *)
CheckedUnsubscribeRequest ==
    { ZeroUnsubscribeRequest }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp32 }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.refApplSubId = one] : one \in Sample(4) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp33 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp33(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp33(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp33 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp33 ==
    { ZeroRequestHeaderComp33 }
        \cup { [ZeroRequestHeaderComp33 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp33 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Side Alloc Ext Grp Comp: 152 bytes                                      *)
(***************************************************************************)

SideAllocExtGrpComp ==
    [ complianceId                : Sample(8),
      individualAllocId           : Sample(4),
      allocQty                    : Sample(4),
      partyExecutingFirm          : Sample(5),
      partyExecutingTrader        : Sample(6),
      side                        : Sample(1),
      tradeAllocStatus            : Sample(1),
      tradingCapacity             : Sample(1),
      positionEffect              : Sample(1),
      account                     : Sample(2),
      partyIdPositionAccount      : Sample(32),
      partyIdTakeUpTradingFirm    : Sample(5),
      freeText1                   : Sample(12),
      freeText2                   : Sample(12),
      freeText3                   : Sample(12),
      partyIdOrderOriginationFirm : Sample(7),
      partyIdBeneficiary          : Sample(9),
      partyIdLocationId           : Sample(2),
      custOrderHandlingInst       : Sample(1),
      complianceText              : Sample(20),
      pad7                        : Sample(7) ]

EncodeSideAllocExtGrpComp(message) ==
    message.complianceId
        \o message.individualAllocId
        \o message.allocQty
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.side
        \o message.tradeAllocStatus
        \o message.tradingCapacity
        \o message.positionEffect
        \o message.account
        \o message.partyIdPositionAccount
        \o message.partyIdTakeUpTradingFirm
        \o message.freeText1
        \o message.freeText2
        \o message.freeText3
        \o message.partyIdOrderOriginationFirm
        \o message.partyIdBeneficiary
        \o message.partyIdLocationId
        \o message.custOrderHandlingInst
        \o message.complianceText
        \o message.pad7

DecodeSideAllocExtGrpComp(bytes) ==
    LET complianceId == ReadBytes(bytes, 8) IN IF ~complianceId.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(complianceId.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET allocQty == ReadBytes(individualAllocId.rest, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(allocQty.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET side == ReadBytes(partyExecutingTrader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET tradeAllocStatus == ReadBytes(side.rest, 1) IN IF ~tradeAllocStatus.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(tradeAllocStatus.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET positionEffect == ReadBytes(tradingCapacity.rest, 1) IN IF ~positionEffect.ok THEN Fail ELSE
    LET account == ReadBytes(positionEffect.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET partyIdPositionAccount == ReadBytes(account.rest, 32) IN IF ~partyIdPositionAccount.ok THEN Fail ELSE
    LET partyIdTakeUpTradingFirm == ReadBytes(partyIdPositionAccount.rest, 5) IN IF ~partyIdTakeUpTradingFirm.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyIdTakeUpTradingFirm.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText3 == ReadBytes(freeText2.rest, 12) IN IF ~freeText3.ok THEN Fail ELSE
    LET partyIdOrderOriginationFirm == ReadBytes(freeText3.rest, 7) IN IF ~partyIdOrderOriginationFirm.ok THEN Fail ELSE
    LET partyIdBeneficiary == ReadBytes(partyIdOrderOriginationFirm.rest, 9) IN IF ~partyIdBeneficiary.ok THEN Fail ELSE
    LET partyIdLocationId == ReadBytes(partyIdBeneficiary.rest, 2) IN IF ~partyIdLocationId.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(partyIdLocationId.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET complianceText == ReadBytes(custOrderHandlingInst.rest, 20) IN IF ~complianceText.ok THEN Fail ELSE
    LET pad7 == ReadBytes(complianceText.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ complianceId                |-> complianceId.value,
         individualAllocId           |-> individualAllocId.value,
         allocQty                    |-> allocQty.value,
         partyExecutingFirm          |-> partyExecutingFirm.value,
         partyExecutingTrader        |-> partyExecutingTrader.value,
         side                        |-> side.value,
         tradeAllocStatus            |-> tradeAllocStatus.value,
         tradingCapacity             |-> tradingCapacity.value,
         positionEffect              |-> positionEffect.value,
         account                     |-> account.value,
         partyIdPositionAccount      |-> partyIdPositionAccount.value,
         partyIdTakeUpTradingFirm    |-> partyIdTakeUpTradingFirm.value,
         freeText1                   |-> freeText1.value,
         freeText2                   |-> freeText2.value,
         freeText3                   |-> freeText3.value,
         partyIdOrderOriginationFirm |-> partyIdOrderOriginationFirm.value,
         partyIdBeneficiary          |-> partyIdBeneficiary.value,
         partyIdLocationId           |-> partyIdLocationId.value,
         custOrderHandlingInst       |-> custOrderHandlingInst.value,
         complianceText              |-> complianceText.value,
         pad7                        |-> pad7.value ], pad7.rest)

ZeroSideAllocExtGrpComp ==
    [ complianceId                |-> [i \in 1 .. 8 |-> 0],
      individualAllocId           |-> [i \in 1 .. 4 |-> 0],
      allocQty                    |-> [i \in 1 .. 4 |-> 0],
      partyExecutingFirm          |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader        |-> [i \in 1 .. 6 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      tradeAllocStatus            |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity             |-> [i \in 1 .. 1 |-> 0],
      positionEffect              |-> [i \in 1 .. 1 |-> 0],
      account                     |-> [i \in 1 .. 2 |-> 0],
      partyIdPositionAccount      |-> [i \in 1 .. 32 |-> 0],
      partyIdTakeUpTradingFirm    |-> [i \in 1 .. 5 |-> 0],
      freeText1                   |-> [i \in 1 .. 12 |-> 0],
      freeText2                   |-> [i \in 1 .. 12 |-> 0],
      freeText3                   |-> [i \in 1 .. 12 |-> 0],
      partyIdOrderOriginationFirm |-> [i \in 1 .. 7 |-> 0],
      partyIdBeneficiary          |-> [i \in 1 .. 9 |-> 0],
      partyIdLocationId           |-> [i \in 1 .. 2 |-> 0],
      custOrderHandlingInst       |-> [i \in 1 .. 1 |-> 0],
      complianceText              |-> [i \in 1 .. 20 |-> 0],
      pad7                        |-> [i \in 1 .. 7 |-> 0] ]

(* Side Alloc Ext Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideAllocExtGrpComp ==
    { ZeroSideAllocExtGrpComp }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.complianceId = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.tradeAllocStatus = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.positionEffect = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdPositionAccount = one] : one \in Sample(32) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdTakeUpTradingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.freeText3 = one] : one \in Sample(12) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdOrderOriginationFirm = one] : one \in Sample(7) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdBeneficiary = one] : one \in Sample(9) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.partyIdLocationId = one] : one \in Sample(2) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.complianceText = one] : one \in Sample(20) }
        \cup { [ZeroSideAllocExtGrpComp EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Side Alloc Ext Grp Comp, written one after another *)
RECURSIVE EncodeSideAllocExtGrpCompList(_)
EncodeSideAllocExtGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSideAllocExtGrpComp(Head(messages)) \o EncodeSideAllocExtGrpCompList(Tail(messages))

(* As many Side Alloc Ext Grp Comp as the field that counts them says *)
RECURSIVE ReadSideAllocExtGrpCompList(_, _)
ReadSideAllocExtGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSideAllocExtGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSideAllocExtGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Side Alloc Ext Grp Comp of each kind, for the lists that carry them *)
OneSideAllocExtGrpComp == { ZeroSideAllocExtGrpComp }

(***************************************************************************)
(* Instrument Event Grp Comp: 8 bytes                                      *)
(***************************************************************************)

InstrumentEventGrpComp2 ==
    [ eventDate : Sample(4),
      eventType : Sample(1),
      pad3      : Sample(3) ]

EncodeInstrumentEventGrpComp2(message) ==
    message.eventDate
        \o message.eventType
        \o message.pad3

DecodeInstrumentEventGrpComp2(bytes) ==
    LET eventDate == ReadBytes(bytes, 4) IN IF ~eventDate.ok THEN Fail ELSE
    LET eventType == ReadBytes(eventDate.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET pad3 == ReadBytes(eventType.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ eventDate |-> eventDate.value,
         eventType |-> eventType.value,
         pad3      |-> pad3.value ], pad3.rest)

ZeroInstrumentEventGrpComp2 ==
    [ eventDate |-> [i \in 1 .. 4 |-> 0],
      eventType |-> [i \in 1 .. 1 |-> 0],
      pad3      |-> [i \in 1 .. 3 |-> 0] ]

(* Instrument Event Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentEventGrpComp2 ==
    { ZeroInstrumentEventGrpComp2 }
        \cup { [ZeroInstrumentEventGrpComp2 EXCEPT !.eventDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentEventGrpComp2 EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentEventGrpComp2 EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Instrument Event Grp Comp, written one after another *)
RECURSIVE EncodeInstrumentEventGrpComp2List(_)
EncodeInstrumentEventGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentEventGrpComp2(Head(messages)) \o EncodeInstrumentEventGrpComp2List(Tail(messages))

(* As many Instrument Event Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrumentEventGrpComp2List(_, _)
ReadInstrumentEventGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentEventGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentEventGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Event Grp Comp of each kind, for the lists that carry them *)
OneInstrumentEventGrpComp2 == { ZeroInstrumentEventGrpComp2 }

(***************************************************************************)
(* Instrument Attribute Grp Comp: 40 bytes                                 *)
(***************************************************************************)

InstrumentAttributeGrpComp2 ==
    [ instrAttribType  : Sample(1),
      instrAttribValue : Sample(32),
      pad7             : Sample(7) ]

EncodeInstrumentAttributeGrpComp2(message) ==
    message.instrAttribType
        \o message.instrAttribValue
        \o message.pad7

DecodeInstrumentAttributeGrpComp2(bytes) ==
    LET instrAttribType == ReadBytes(bytes, 1) IN IF ~instrAttribType.ok THEN Fail ELSE
    LET instrAttribValue == ReadBytes(instrAttribType.rest, 32) IN IF ~instrAttribValue.ok THEN Fail ELSE
    LET pad7 == ReadBytes(instrAttribValue.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ instrAttribType  |-> instrAttribType.value,
         instrAttribValue |-> instrAttribValue.value,
         pad7             |-> pad7.value ], pad7.rest)

ZeroInstrumentAttributeGrpComp2 ==
    [ instrAttribType  |-> [i \in 1 .. 1 |-> 0],
      instrAttribValue |-> [i \in 1 .. 32 |-> 0],
      pad7             |-> [i \in 1 .. 7 |-> 0] ]

(* Instrument Attribute Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentAttributeGrpComp2 ==
    { ZeroInstrumentAttributeGrpComp2 }
        \cup { [ZeroInstrumentAttributeGrpComp2 EXCEPT !.instrAttribType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentAttributeGrpComp2 EXCEPT !.instrAttribValue = one] : one \in Sample(32) }
        \cup { [ZeroInstrumentAttributeGrpComp2 EXCEPT !.pad7 = one] : one \in Sample(7) }

(* A run of Instrument Attribute Grp Comp, written one after another *)
RECURSIVE EncodeInstrumentAttributeGrpComp2List(_)
EncodeInstrumentAttributeGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentAttributeGrpComp2(Head(messages)) \o EncodeInstrumentAttributeGrpComp2List(Tail(messages))

(* As many Instrument Attribute Grp Comp as the field that counts them says *)
RECURSIVE ReadInstrumentAttributeGrpComp2List(_, _)
ReadInstrumentAttributeGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentAttributeGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentAttributeGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Attribute Grp Comp of each kind, for the lists that carry them *)
OneInstrumentAttributeGrpComp2 == { ZeroInstrumentAttributeGrpComp2 }

(***************************************************************************)
(* Underlying Stip Grp Comp: 40 bytes                                      *)
(***************************************************************************)

UnderlyingStipGrpComp2 ==
    [ underlyingStipValue : Sample(32),
      underlyingStipType  : Sample(7),
      pad1                : Sample(1) ]

EncodeUnderlyingStipGrpComp2(message) ==
    message.underlyingStipValue
        \o message.underlyingStipType
        \o message.pad1

DecodeUnderlyingStipGrpComp2(bytes) ==
    LET underlyingStipValue == ReadBytes(bytes, 32) IN IF ~underlyingStipValue.ok THEN Fail ELSE
    LET underlyingStipType == ReadBytes(underlyingStipValue.rest, 7) IN IF ~underlyingStipType.ok THEN Fail ELSE
    LET pad1 == ReadBytes(underlyingStipType.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ underlyingStipValue |-> underlyingStipValue.value,
         underlyingStipType  |-> underlyingStipType.value,
         pad1                |-> pad1.value ], pad1.rest)

ZeroUnderlyingStipGrpComp2 ==
    [ underlyingStipValue |-> [i \in 1 .. 32 |-> 0],
      underlyingStipType  |-> [i \in 1 .. 7 |-> 0],
      pad1                |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Stip Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingStipGrpComp2 ==
    { ZeroUnderlyingStipGrpComp2 }
        \cup { [ZeroUnderlyingStipGrpComp2 EXCEPT !.underlyingStipValue = one] : one \in Sample(32) }
        \cup { [ZeroUnderlyingStipGrpComp2 EXCEPT !.underlyingStipType = one] : one \in Sample(7) }
        \cup { [ZeroUnderlyingStipGrpComp2 EXCEPT !.pad1 = one] : one \in Sample(1) }

(* A run of Underlying Stip Grp Comp, written one after another *)
RECURSIVE EncodeUnderlyingStipGrpComp2List(_)
EncodeUnderlyingStipGrpComp2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUnderlyingStipGrpComp2(Head(messages)) \o EncodeUnderlyingStipGrpComp2List(Tail(messages))

(* As many Underlying Stip Grp Comp as the field that counts them says *)
RECURSIVE ReadUnderlyingStipGrpComp2List(_, _)
ReadUnderlyingStipGrpComp2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUnderlyingStipGrpComp2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUnderlyingStipGrpComp2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Underlying Stip Grp Comp of each kind, for the lists that carry them *)
OneUnderlyingStipGrpComp2 == { ZeroUnderlyingStipGrpComp2 }

(***************************************************************************)
(* Upload Tes Trade Request                                                *)
(***************************************************************************)

UploadTesTradeRequest ==
    [ networkMsgId               : Sample(8),
      pad2                       : Sample(2),
      requestHeaderComp          : RequestHeaderComp33,
      securityId                 : Sample(8),
      lastPx                     : Sample(8),
      transBkdTime               : Sample(8),
      underlyingPx               : Sample(8),
      underlyingQty              : Sample(8),
      relatedClosePrice          : Sample(8),
      marketSegmentId            : Sample(4),
      underlyingSettlementDate   : Sample(4),
      underlyingMaturityDate     : Sample(4),
      relatedTradeId             : Sample(4),
      relatedMarketSegmentId     : Sample(4),
      relatedTradeQuantity       : Sample(4),
      trdType                    : Sample(2),
      productComplex             : Sample(1),
      tradeReportType            : Sample(1),
      tradePublishIndicator      : Sample(1),
      skipValidations            : Sample(1),
      hedgeType                  : Sample(1),
      partyIdSettlementLocation  : Sample(1),
      tradeReportId              : Sample(20),
      tradeReportText            : Sample(20),
      underlyingSecurityId       : Sample(12),
      underlyingSecurityDesc     : Sample(30),
      underlyingCurrency         : Sample(3),
      underlyingIssuer           : Sample(30),
      pad1                       : Sample(1),
      sideAllocExtGrpComp        : SampleLists(OneSideAllocExtGrpComp),
      instrumentEventGrpComp     : SampleLists(OneInstrumentEventGrpComp2),
      instrumentAttributeGrpComp : SampleLists(OneInstrumentAttributeGrpComp2),
      underlyingStipGrpComp      : SampleLists(OneUnderlyingStipGrpComp2) ]

EncodeUploadTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp33(message.requestHeaderComp)
        \o message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.underlyingPx
        \o message.underlyingQty
        \o message.relatedClosePrice
        \o message.marketSegmentId
        \o message.underlyingSettlementDate
        \o message.underlyingMaturityDate
        \o message.relatedTradeId
        \o message.relatedMarketSegmentId
        \o message.relatedTradeQuantity
        \o message.trdType
        \o message.productComplex
        \o message.tradeReportType
        \o message.tradePublishIndicator
        \o EncodeUIntBE(Len(message.sideAllocExtGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrumentEventGrpComp), 1)
        \o EncodeUIntBE(Len(message.instrumentAttributeGrpComp), 1)
        \o EncodeUIntBE(Len(message.underlyingStipGrpComp), 1)
        \o message.skipValidations
        \o message.hedgeType
        \o message.partyIdSettlementLocation
        \o message.tradeReportId
        \o message.tradeReportText
        \o message.underlyingSecurityId
        \o message.underlyingSecurityDesc
        \o message.underlyingCurrency
        \o message.underlyingIssuer
        \o message.pad1
        \o EncodeSideAllocExtGrpCompList(message.sideAllocExtGrpComp)
        \o EncodeInstrumentEventGrpComp2List(message.instrumentEventGrpComp)
        \o EncodeInstrumentAttributeGrpComp2List(message.instrumentAttributeGrpComp)
        \o EncodeUnderlyingStipGrpComp2List(message.underlyingStipGrpComp)

DecodeUploadTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp33(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET underlyingPx == ReadBytes(transBkdTime.rest, 8) IN IF ~underlyingPx.ok THEN Fail ELSE
    LET underlyingQty == ReadBytes(underlyingPx.rest, 8) IN IF ~underlyingQty.ok THEN Fail ELSE
    LET relatedClosePrice == ReadBytes(underlyingQty.rest, 8) IN IF ~relatedClosePrice.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(relatedClosePrice.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET underlyingSettlementDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~underlyingSettlementDate.ok THEN Fail ELSE
    LET underlyingMaturityDate == ReadBytes(underlyingSettlementDate.rest, 4) IN IF ~underlyingMaturityDate.ok THEN Fail ELSE
    LET relatedTradeId == ReadBytes(underlyingMaturityDate.rest, 4) IN IF ~relatedTradeId.ok THEN Fail ELSE
    LET relatedMarketSegmentId == ReadBytes(relatedTradeId.rest, 4) IN IF ~relatedMarketSegmentId.ok THEN Fail ELSE
    LET relatedTradeQuantity == ReadBytes(relatedMarketSegmentId.rest, 4) IN IF ~relatedTradeQuantity.ok THEN Fail ELSE
    LET trdType == ReadBytes(relatedTradeQuantity.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET productComplex == ReadBytes(trdType.rest, 1) IN IF ~productComplex.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(productComplex.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradePublishIndicator == ReadBytes(tradeReportType.rest, 1) IN IF ~tradePublishIndicator.ok THEN Fail ELSE
    LET noSideAllocs == ReadUIntBE(tradePublishIndicator.rest, 1) IN IF ~noSideAllocs.ok THEN Fail ELSE
    LET noEvents == ReadUIntBE(noSideAllocs.rest, 1) IN IF ~noEvents.ok THEN Fail ELSE
    LET noInstrAttrib == ReadUIntBE(noEvents.rest, 1) IN IF ~noInstrAttrib.ok THEN Fail ELSE
    LET noUnderlyingStips == ReadUIntBE(noInstrAttrib.rest, 1) IN IF ~noUnderlyingStips.ok THEN Fail ELSE
    LET skipValidations == ReadBytes(noUnderlyingStips.rest, 1) IN IF ~skipValidations.ok THEN Fail ELSE
    LET hedgeType == ReadBytes(skipValidations.rest, 1) IN IF ~hedgeType.ok THEN Fail ELSE
    LET partyIdSettlementLocation == ReadBytes(hedgeType.rest, 1) IN IF ~partyIdSettlementLocation.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(partyIdSettlementLocation.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(tradeReportId.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET underlyingSecurityId == ReadBytes(tradeReportText.rest, 12) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET underlyingSecurityDesc == ReadBytes(underlyingSecurityId.rest, 30) IN IF ~underlyingSecurityDesc.ok THEN Fail ELSE
    LET underlyingCurrency == ReadBytes(underlyingSecurityDesc.rest, 3) IN IF ~underlyingCurrency.ok THEN Fail ELSE
    LET underlyingIssuer == ReadBytes(underlyingCurrency.rest, 30) IN IF ~underlyingIssuer.ok THEN Fail ELSE
    LET pad1 == ReadBytes(underlyingIssuer.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET sideAllocExtGrpComp == ReadSideAllocExtGrpCompList(pad1.rest, noSideAllocs.value) IN IF ~sideAllocExtGrpComp.ok THEN Fail ELSE
    LET instrumentEventGrpComp == ReadInstrumentEventGrpComp2List(sideAllocExtGrpComp.rest, noEvents.value) IN IF ~instrumentEventGrpComp.ok THEN Fail ELSE
    LET instrumentAttributeGrpComp == ReadInstrumentAttributeGrpComp2List(instrumentEventGrpComp.rest, noInstrAttrib.value) IN IF ~instrumentAttributeGrpComp.ok THEN Fail ELSE
    LET underlyingStipGrpComp == ReadUnderlyingStipGrpComp2List(instrumentAttributeGrpComp.rest, noUnderlyingStips.value) IN IF ~underlyingStipGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId               |-> networkMsgId.value,
         pad2                       |-> pad2.value,
         requestHeaderComp          |-> requestHeaderComp.value,
         securityId                 |-> securityId.value,
         lastPx                     |-> lastPx.value,
         transBkdTime               |-> transBkdTime.value,
         underlyingPx               |-> underlyingPx.value,
         underlyingQty              |-> underlyingQty.value,
         relatedClosePrice          |-> relatedClosePrice.value,
         marketSegmentId            |-> marketSegmentId.value,
         underlyingSettlementDate   |-> underlyingSettlementDate.value,
         underlyingMaturityDate     |-> underlyingMaturityDate.value,
         relatedTradeId             |-> relatedTradeId.value,
         relatedMarketSegmentId     |-> relatedMarketSegmentId.value,
         relatedTradeQuantity       |-> relatedTradeQuantity.value,
         trdType                    |-> trdType.value,
         productComplex             |-> productComplex.value,
         tradeReportType            |-> tradeReportType.value,
         tradePublishIndicator      |-> tradePublishIndicator.value,
         skipValidations            |-> skipValidations.value,
         hedgeType                  |-> hedgeType.value,
         partyIdSettlementLocation  |-> partyIdSettlementLocation.value,
         tradeReportId              |-> tradeReportId.value,
         tradeReportText            |-> tradeReportText.value,
         underlyingSecurityId       |-> underlyingSecurityId.value,
         underlyingSecurityDesc     |-> underlyingSecurityDesc.value,
         underlyingCurrency         |-> underlyingCurrency.value,
         underlyingIssuer           |-> underlyingIssuer.value,
         pad1                       |-> pad1.value,
         sideAllocExtGrpComp        |-> sideAllocExtGrpComp.value,
         instrumentEventGrpComp     |-> instrumentEventGrpComp.value,
         instrumentAttributeGrpComp |-> instrumentAttributeGrpComp.value,
         underlyingStipGrpComp      |-> underlyingStipGrpComp.value ], underlyingStipGrpComp.rest)

ZeroUploadTesTradeRequest ==
    [ networkMsgId               |-> [i \in 1 .. 8 |-> 0],
      pad2                       |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp          |-> ZeroRequestHeaderComp33,
      securityId                 |-> [i \in 1 .. 8 |-> 0],
      lastPx                     |-> [i \in 1 .. 8 |-> 0],
      transBkdTime               |-> [i \in 1 .. 8 |-> 0],
      underlyingPx               |-> [i \in 1 .. 8 |-> 0],
      underlyingQty              |-> [i \in 1 .. 8 |-> 0],
      relatedClosePrice          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId            |-> [i \in 1 .. 4 |-> 0],
      underlyingSettlementDate   |-> [i \in 1 .. 4 |-> 0],
      underlyingMaturityDate     |-> [i \in 1 .. 4 |-> 0],
      relatedTradeId             |-> [i \in 1 .. 4 |-> 0],
      relatedMarketSegmentId     |-> [i \in 1 .. 4 |-> 0],
      relatedTradeQuantity       |-> [i \in 1 .. 4 |-> 0],
      trdType                    |-> [i \in 1 .. 2 |-> 0],
      productComplex             |-> [i \in 1 .. 1 |-> 0],
      tradeReportType            |-> [i \in 1 .. 1 |-> 0],
      tradePublishIndicator      |-> [i \in 1 .. 1 |-> 0],
      skipValidations            |-> [i \in 1 .. 1 |-> 0],
      hedgeType                  |-> [i \in 1 .. 1 |-> 0],
      partyIdSettlementLocation  |-> [i \in 1 .. 1 |-> 0],
      tradeReportId              |-> [i \in 1 .. 20 |-> 0],
      tradeReportText            |-> [i \in 1 .. 20 |-> 0],
      underlyingSecurityId       |-> [i \in 1 .. 12 |-> 0],
      underlyingSecurityDesc     |-> [i \in 1 .. 30 |-> 0],
      underlyingCurrency         |-> [i \in 1 .. 3 |-> 0],
      underlyingIssuer           |-> [i \in 1 .. 30 |-> 0],
      pad1                       |-> [i \in 1 .. 1 |-> 0],
      sideAllocExtGrpComp        |-> << >>,
      instrumentEventGrpComp     |-> << >>,
      instrumentAttributeGrpComp |-> << >>,
      underlyingStipGrpComp      |-> << >> ]

(* Upload Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedUploadTesTradeRequest ==
    { ZeroUploadTesTradeRequest }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp33 }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingPx = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingQty = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.relatedClosePrice = one] : one \in Sample(8) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingSettlementDate = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingMaturityDate = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.relatedTradeId = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.relatedMarketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.relatedTradeQuantity = one] : one \in Sample(4) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.productComplex = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.tradePublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.skipValidations = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.hedgeType = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.partyIdSettlementLocation = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingSecurityId = one] : one \in Sample(12) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingSecurityDesc = one] : one \in Sample(30) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingIssuer = one] : one \in Sample(30) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.sideAllocExtGrpComp = one] : one \in SampleLists(OneSideAllocExtGrpComp) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.instrumentEventGrpComp = one] : one \in SampleLists(OneInstrumentEventGrpComp2) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.instrumentAttributeGrpComp = one] : one \in SampleLists(OneInstrumentAttributeGrpComp2) }
        \cup { [ZeroUploadTesTradeRequest EXCEPT !.underlyingStipGrpComp = one] : one \in SampleLists(OneUnderlyingStipGrpComp2) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp34 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp34(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp34(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp34 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp34 ==
    { ZeroRequestHeaderComp34 }
        \cup { [ZeroRequestHeaderComp34 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp34 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* User Login Request: 58 bytes                                            *)
(***************************************************************************)

UserLoginRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp34,
      username          : Sample(4),
      password          : Sample(32),
      pad4              : Sample(4) ]

EncodeUserLoginRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp34(message.requestHeaderComp)
        \o message.username
        \o message.password
        \o message.pad4

DecodeUserLoginRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp34(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp34,
      username          |-> [i \in 1 .. 4 |-> 0],
      password          |-> [i \in 1 .. 32 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* User Login Request at zero, then each field in turn at the values it is checked at *)
CheckedUserLoginRequest ==
    { ZeroUserLoginRequest }
        \cup { [ZeroUserLoginRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserLoginRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLoginRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp34 }
        \cup { [ZeroUserLoginRequest EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserLoginRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroUserLoginRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp35 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp35(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp35(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp35 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp35 ==
    { ZeroRequestHeaderComp35 }
        \cup { [ZeroRequestHeaderComp35 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp35 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* User Logout Request: 26 bytes                                           *)
(***************************************************************************)

UserLogoutRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp35,
      username          : Sample(4),
      pad4              : Sample(4) ]

EncodeUserLogoutRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp35(message.requestHeaderComp)
        \o message.username
        \o message.pad4

DecodeUserLogoutRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp35(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp35,
      username          |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* User Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedUserLogoutRequest ==
    { ZeroUserLogoutRequest }
        \cup { [ZeroUserLogoutRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp35 }
        \cup { [ZeroUserLogoutRequest EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

AddComplexInstrumentRequestCode == 10301  \* 0x283d
AddFlexibleInstrumentRequestCode == 10309  \* 0x2845
ApproveTesTradeRequestCode == 10603  \* 0x296b
CrossRequestCode == 10118  \* 0x2786
DeleteAllOrderRequestCode == 10120  \* 0x2788
DeleteAllQuoteRequestCode == 10408  \* 0x28a8
DeleteOrderComplexRequestCode == 10123  \* 0x278b
DeleteOrderSingleRequestCode == 10109  \* 0x277d
DeleteTesTradeRequestCode == 10602  \* 0x296a
EnterTesTradeRequestCode == 10600  \* 0x2968
GatewayRequestCode == 10020  \* 0x2724
HeartbeatCode == 10011  \* 0x271b
InquireEnrichmentRuleIdListRequestCode == 10040  \* 0x2738
InquireMmParameterRequestCode == 10305  \* 0x2841
InquireSessionListRequestCode == 10035  \* 0x2733
InquireUserRequestCode == 10038  \* 0x2736
LogonRequestCode == 10000  \* 0x2710
LogoutRequestCode == 10002  \* 0x2712
MmParameterDefinitionRequestCode == 10303  \* 0x283f
MassQuoteRequestCode == 10405  \* 0x28a5
ModifyOrderComplexRequestCode == 10114  \* 0x2782
ModifyOrderSingleRequestCode == 10106  \* 0x277a
ModifyOrderSingleShortRequestCode == 10126  \* 0x278e
ModifyTesTradeRequestCode == 10601  \* 0x2969
NewOrderComplexRequestCode == 10113  \* 0x2781
NewOrderSingleRequestCode == 10100  \* 0x2774
NewOrderSingleShortRequestCode == 10125  \* 0x278d
QuoteActivationRequestCode == 10403  \* 0x28a3
RfqRequestCode == 10401  \* 0x28a1
RetransmitMeMessageRequestCode == 10026  \* 0x272a
RetransmitRequestCode == 10008  \* 0x2718
SubscribeRequestCode == 10025  \* 0x2729
UnsubscribeRequestCode == 10006  \* 0x2716
UploadTesTradeRequestCode == 10612  \* 0x2974
UserLoginRequestCode == 10018  \* 0x2722
UserLogoutRequestCode == 10029  \* 0x272d

ClientPayload ==
    [ tag : {AddComplexInstrumentRequestCode}, body : AddComplexInstrumentRequest ]
        \cup [ tag : {AddFlexibleInstrumentRequestCode}, body : AddFlexibleInstrumentRequest ]
        \cup [ tag : {ApproveTesTradeRequestCode}, body : ApproveTesTradeRequest ]
        \cup [ tag : {CrossRequestCode}, body : CrossRequest ]
        \cup [ tag : {DeleteAllOrderRequestCode}, body : DeleteAllOrderRequest ]
        \cup [ tag : {DeleteAllQuoteRequestCode}, body : DeleteAllQuoteRequest ]
        \cup [ tag : {DeleteOrderComplexRequestCode}, body : DeleteOrderComplexRequest ]
        \cup [ tag : {DeleteOrderSingleRequestCode}, body : DeleteOrderSingleRequest ]
        \cup [ tag : {DeleteTesTradeRequestCode}, body : DeleteTesTradeRequest ]
        \cup [ tag : {EnterTesTradeRequestCode}, body : EnterTesTradeRequest ]
        \cup [ tag : {GatewayRequestCode}, body : GatewayRequest ]
        \cup [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {InquireEnrichmentRuleIdListRequestCode}, body : InquireEnrichmentRuleIdListRequest ]
        \cup [ tag : {InquireMmParameterRequestCode}, body : InquireMmParameterRequest ]
        \cup [ tag : {InquireSessionListRequestCode}, body : InquireSessionListRequest ]
        \cup [ tag : {InquireUserRequestCode}, body : InquireUserRequest ]
        \cup [ tag : {LogonRequestCode}, body : LogonRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {MmParameterDefinitionRequestCode}, body : MmParameterDefinitionRequest ]
        \cup [ tag : {MassQuoteRequestCode}, body : MassQuoteRequest ]
        \cup [ tag : {ModifyOrderComplexRequestCode}, body : ModifyOrderComplexRequest ]
        \cup [ tag : {ModifyOrderSingleRequestCode}, body : ModifyOrderSingleRequest ]
        \cup [ tag : {ModifyOrderSingleShortRequestCode}, body : ModifyOrderSingleShortRequest ]
        \cup [ tag : {ModifyTesTradeRequestCode}, body : ModifyTesTradeRequest ]
        \cup [ tag : {NewOrderComplexRequestCode}, body : NewOrderComplexRequest ]
        \cup [ tag : {NewOrderSingleRequestCode}, body : NewOrderSingleRequest ]
        \cup [ tag : {NewOrderSingleShortRequestCode}, body : NewOrderSingleShortRequest ]
        \cup [ tag : {QuoteActivationRequestCode}, body : QuoteActivationRequest ]
        \cup [ tag : {RfqRequestCode}, body : RfqRequest ]
        \cup [ tag : {RetransmitMeMessageRequestCode}, body : RetransmitMeMessageRequest ]
        \cup [ tag : {RetransmitRequestCode}, body : RetransmitRequest ]
        \cup [ tag : {SubscribeRequestCode}, body : SubscribeRequest ]
        \cup [ tag : {UnsubscribeRequestCode}, body : UnsubscribeRequest ]
        \cup [ tag : {UploadTesTradeRequestCode}, body : UploadTesTradeRequest ]
        \cup [ tag : {UserLoginRequestCode}, body : UserLoginRequest ]
        \cup [ tag : {UserLogoutRequestCode}, body : UserLogoutRequest ]

EncodeClientPayload(message) ==
    CASE message.tag = AddComplexInstrumentRequestCode -> EncodeAddComplexInstrumentRequest(message.body)
      [] message.tag = AddFlexibleInstrumentRequestCode -> EncodeAddFlexibleInstrumentRequest(message.body)
      [] message.tag = ApproveTesTradeRequestCode -> EncodeApproveTesTradeRequest(message.body)
      [] message.tag = CrossRequestCode -> EncodeCrossRequest(message.body)
      [] message.tag = DeleteAllOrderRequestCode -> EncodeDeleteAllOrderRequest(message.body)
      [] message.tag = DeleteAllQuoteRequestCode -> EncodeDeleteAllQuoteRequest(message.body)
      [] message.tag = DeleteOrderComplexRequestCode -> EncodeDeleteOrderComplexRequest(message.body)
      [] message.tag = DeleteOrderSingleRequestCode -> EncodeDeleteOrderSingleRequest(message.body)
      [] message.tag = DeleteTesTradeRequestCode -> EncodeDeleteTesTradeRequest(message.body)
      [] message.tag = EnterTesTradeRequestCode -> EncodeEnterTesTradeRequest(message.body)
      [] message.tag = GatewayRequestCode -> EncodeGatewayRequest(message.body)
      [] message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = InquireEnrichmentRuleIdListRequestCode -> EncodeInquireEnrichmentRuleIdListRequest(message.body)
      [] message.tag = InquireMmParameterRequestCode -> EncodeInquireMmParameterRequest(message.body)
      [] message.tag = InquireSessionListRequestCode -> EncodeInquireSessionListRequest(message.body)
      [] message.tag = InquireUserRequestCode -> EncodeInquireUserRequest(message.body)
      [] message.tag = LogonRequestCode -> EncodeLogonRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = MmParameterDefinitionRequestCode -> EncodeMmParameterDefinitionRequest(message.body)
      [] message.tag = MassQuoteRequestCode -> EncodeMassQuoteRequest(message.body)
      [] message.tag = ModifyOrderComplexRequestCode -> EncodeModifyOrderComplexRequest(message.body)
      [] message.tag = ModifyOrderSingleRequestCode -> EncodeModifyOrderSingleRequest(message.body)
      [] message.tag = ModifyOrderSingleShortRequestCode -> EncodeModifyOrderSingleShortRequest(message.body)
      [] message.tag = ModifyTesTradeRequestCode -> EncodeModifyTesTradeRequest(message.body)
      [] message.tag = NewOrderComplexRequestCode -> EncodeNewOrderComplexRequest(message.body)
      [] message.tag = NewOrderSingleRequestCode -> EncodeNewOrderSingleRequest(message.body)
      [] message.tag = NewOrderSingleShortRequestCode -> EncodeNewOrderSingleShortRequest(message.body)
      [] message.tag = QuoteActivationRequestCode -> EncodeQuoteActivationRequest(message.body)
      [] message.tag = RfqRequestCode -> EncodeRfqRequest(message.body)
      [] message.tag = RetransmitMeMessageRequestCode -> EncodeRetransmitMeMessageRequest(message.body)
      [] message.tag = RetransmitRequestCode -> EncodeRetransmitRequest(message.body)
      [] message.tag = SubscribeRequestCode -> EncodeSubscribeRequest(message.body)
      [] message.tag = UnsubscribeRequestCode -> EncodeUnsubscribeRequest(message.body)
      [] message.tag = UploadTesTradeRequestCode -> EncodeUploadTesTradeRequest(message.body)
      [] message.tag = UserLoginRequestCode -> EncodeUserLoginRequest(message.body)
      [] message.tag = UserLogoutRequestCode -> EncodeUserLogoutRequest(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = AddComplexInstrumentRequestCode -> DecodeAddComplexInstrumentRequest(bytes)
              [] tag = AddFlexibleInstrumentRequestCode -> DecodeAddFlexibleInstrumentRequest(bytes)
              [] tag = ApproveTesTradeRequestCode -> DecodeApproveTesTradeRequest(bytes)
              [] tag = CrossRequestCode -> DecodeCrossRequest(bytes)
              [] tag = DeleteAllOrderRequestCode -> DecodeDeleteAllOrderRequest(bytes)
              [] tag = DeleteAllQuoteRequestCode -> DecodeDeleteAllQuoteRequest(bytes)
              [] tag = DeleteOrderComplexRequestCode -> DecodeDeleteOrderComplexRequest(bytes)
              [] tag = DeleteOrderSingleRequestCode -> DecodeDeleteOrderSingleRequest(bytes)
              [] tag = DeleteTesTradeRequestCode -> DecodeDeleteTesTradeRequest(bytes)
              [] tag = EnterTesTradeRequestCode -> DecodeEnterTesTradeRequest(bytes)
              [] tag = GatewayRequestCode -> DecodeGatewayRequest(bytes)
              [] tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = InquireEnrichmentRuleIdListRequestCode -> DecodeInquireEnrichmentRuleIdListRequest(bytes)
              [] tag = InquireMmParameterRequestCode -> DecodeInquireMmParameterRequest(bytes)
              [] tag = InquireSessionListRequestCode -> DecodeInquireSessionListRequest(bytes)
              [] tag = InquireUserRequestCode -> DecodeInquireUserRequest(bytes)
              [] tag = LogonRequestCode -> DecodeLogonRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = MmParameterDefinitionRequestCode -> DecodeMmParameterDefinitionRequest(bytes)
              [] tag = MassQuoteRequestCode -> DecodeMassQuoteRequest(bytes)
              [] tag = ModifyOrderComplexRequestCode -> DecodeModifyOrderComplexRequest(bytes)
              [] tag = ModifyOrderSingleRequestCode -> DecodeModifyOrderSingleRequest(bytes)
              [] tag = ModifyOrderSingleShortRequestCode -> DecodeModifyOrderSingleShortRequest(bytes)
              [] tag = ModifyTesTradeRequestCode -> DecodeModifyTesTradeRequest(bytes)
              [] tag = NewOrderComplexRequestCode -> DecodeNewOrderComplexRequest(bytes)
              [] tag = NewOrderSingleRequestCode -> DecodeNewOrderSingleRequest(bytes)
              [] tag = NewOrderSingleShortRequestCode -> DecodeNewOrderSingleShortRequest(bytes)
              [] tag = QuoteActivationRequestCode -> DecodeQuoteActivationRequest(bytes)
              [] tag = RfqRequestCode -> DecodeRfqRequest(bytes)
              [] tag = RetransmitMeMessageRequestCode -> DecodeRetransmitMeMessageRequest(bytes)
              [] tag = RetransmitRequestCode -> DecodeRetransmitRequest(bytes)
              [] tag = SubscribeRequestCode -> DecodeSubscribeRequest(bytes)
              [] tag = UnsubscribeRequestCode -> DecodeUnsubscribeRequest(bytes)
              [] tag = UploadTesTradeRequestCode -> DecodeUploadTesTradeRequest(bytes)
              [] tag = UserLoginRequestCode -> DecodeUserLoginRequest(bytes)
              [] tag = UserLogoutRequestCode -> DecodeUserLogoutRequest(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> AddComplexInstrumentRequestCode, body |-> ZeroAddComplexInstrumentRequest]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> AddComplexInstrumentRequestCode, body |-> one] : one \in CheckedAddComplexInstrumentRequest }
        \cup { [tag |-> AddFlexibleInstrumentRequestCode, body |-> one] : one \in CheckedAddFlexibleInstrumentRequest }
        \cup { [tag |-> ApproveTesTradeRequestCode, body |-> one] : one \in CheckedApproveTesTradeRequest }
        \cup { [tag |-> CrossRequestCode, body |-> one] : one \in CheckedCrossRequest }
        \cup { [tag |-> DeleteAllOrderRequestCode, body |-> one] : one \in CheckedDeleteAllOrderRequest }
        \cup { [tag |-> DeleteAllQuoteRequestCode, body |-> one] : one \in CheckedDeleteAllQuoteRequest }
        \cup { [tag |-> DeleteOrderComplexRequestCode, body |-> one] : one \in CheckedDeleteOrderComplexRequest }
        \cup { [tag |-> DeleteOrderSingleRequestCode, body |-> one] : one \in CheckedDeleteOrderSingleRequest }
        \cup { [tag |-> DeleteTesTradeRequestCode, body |-> one] : one \in CheckedDeleteTesTradeRequest }
        \cup { [tag |-> EnterTesTradeRequestCode, body |-> one] : one \in CheckedEnterTesTradeRequest }
        \cup { [tag |-> GatewayRequestCode, body |-> one] : one \in CheckedGatewayRequest }
        \cup { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> InquireEnrichmentRuleIdListRequestCode, body |-> one] : one \in CheckedInquireEnrichmentRuleIdListRequest }
        \cup { [tag |-> InquireMmParameterRequestCode, body |-> one] : one \in CheckedInquireMmParameterRequest }
        \cup { [tag |-> InquireSessionListRequestCode, body |-> one] : one \in CheckedInquireSessionListRequest }
        \cup { [tag |-> InquireUserRequestCode, body |-> one] : one \in CheckedInquireUserRequest }
        \cup { [tag |-> LogonRequestCode, body |-> one] : one \in CheckedLogonRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> MmParameterDefinitionRequestCode, body |-> one] : one \in CheckedMmParameterDefinitionRequest }
        \cup { [tag |-> MassQuoteRequestCode, body |-> one] : one \in CheckedMassQuoteRequest }
        \cup { [tag |-> ModifyOrderComplexRequestCode, body |-> one] : one \in CheckedModifyOrderComplexRequest }
        \cup { [tag |-> ModifyOrderSingleRequestCode, body |-> one] : one \in CheckedModifyOrderSingleRequest }
        \cup { [tag |-> ModifyOrderSingleShortRequestCode, body |-> one] : one \in CheckedModifyOrderSingleShortRequest }
        \cup { [tag |-> ModifyTesTradeRequestCode, body |-> one] : one \in CheckedModifyTesTradeRequest }
        \cup { [tag |-> NewOrderComplexRequestCode, body |-> one] : one \in CheckedNewOrderComplexRequest }
        \cup { [tag |-> NewOrderSingleRequestCode, body |-> one] : one \in CheckedNewOrderSingleRequest }
        \cup { [tag |-> NewOrderSingleShortRequestCode, body |-> one] : one \in CheckedNewOrderSingleShortRequest }
        \cup { [tag |-> QuoteActivationRequestCode, body |-> one] : one \in CheckedQuoteActivationRequest }
        \cup { [tag |-> RfqRequestCode, body |-> one] : one \in CheckedRfqRequest }
        \cup { [tag |-> RetransmitMeMessageRequestCode, body |-> one] : one \in CheckedRetransmitMeMessageRequest }
        \cup { [tag |-> RetransmitRequestCode, body |-> one] : one \in CheckedRetransmitRequest }
        \cup { [tag |-> SubscribeRequestCode, body |-> one] : one \in CheckedSubscribeRequest }
        \cup { [tag |-> UnsubscribeRequestCode, body |-> one] : one \in CheckedUnsubscribeRequest }
        \cup { [tag |-> UploadTesTradeRequestCode, body |-> one] : one \in CheckedUploadTesTradeRequest }
        \cup { [tag |-> UserLoginRequestCode, body |-> one] : one \in CheckedUserLoginRequest }
        \cup { [tag |-> UserLogoutRequestCode, body |-> one] : one \in CheckedUserLogoutRequest }

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
    { [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> AddComplexInstrumentRequestCode, body |-> ZeroAddComplexInstrumentRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> AddFlexibleInstrumentRequestCode, body |-> ZeroAddFlexibleInstrumentRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ApproveTesTradeRequestCode, body |-> ZeroApproveTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> CrossRequestCode, body |-> ZeroCrossRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteAllOrderRequestCode, body |-> ZeroDeleteAllOrderRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteAllQuoteRequestCode, body |-> ZeroDeleteAllQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteOrderComplexRequestCode, body |-> ZeroDeleteOrderComplexRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteOrderSingleRequestCode, body |-> ZeroDeleteOrderSingleRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteTesTradeRequestCode, body |-> ZeroDeleteTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> EnterTesTradeRequestCode, body |-> ZeroEnterTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> GatewayRequestCode, body |-> ZeroGatewayRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> HeartbeatCode, body |-> ZeroHeartbeat]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireEnrichmentRuleIdListRequestCode, body |-> ZeroInquireEnrichmentRuleIdListRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireMmParameterRequestCode, body |-> ZeroInquireMmParameterRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireSessionListRequestCode, body |-> ZeroInquireSessionListRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireUserRequestCode, body |-> ZeroInquireUserRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogonRequestCode, body |-> ZeroLogonRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> MmParameterDefinitionRequestCode, body |-> ZeroMmParameterDefinitionRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> MassQuoteRequestCode, body |-> ZeroMassQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderComplexRequestCode, body |-> ZeroModifyOrderComplexRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderSingleRequestCode, body |-> ZeroModifyOrderSingleRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderSingleShortRequestCode, body |-> ZeroModifyOrderSingleShortRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyTesTradeRequestCode, body |-> ZeroModifyTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderComplexRequestCode, body |-> ZeroNewOrderComplexRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderSingleRequestCode, body |-> ZeroNewOrderSingleRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderSingleShortRequestCode, body |-> ZeroNewOrderSingleShortRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> QuoteActivationRequestCode, body |-> ZeroQuoteActivationRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RfqRequestCode, body |-> ZeroRfqRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmitMeMessageRequestCode, body |-> ZeroRetransmitMeMessageRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmitRequestCode, body |-> ZeroRetransmitRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SubscribeRequestCode, body |-> ZeroSubscribeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UnsubscribeRequestCode, body |-> ZeroUnsubscribeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UploadTesTradeRequestCode, body |-> ZeroUploadTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserLoginRequestCode, body |-> ZeroUserLoginRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserLogoutRequestCode, body |-> ZeroUserLogoutRequest]] }

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

(* Every Instrmt Leg Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrmtLegGrpComp ==
    \A message \in CheckedInstrmtLegGrpComp :
        LET read == DecodeInstrmtLegGrpComp(EncodeInstrmtLegGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Complex Instrument Request decodes back to what was encoded, and leaves nothing over *)
RoundTripAddComplexInstrumentRequest ==
    \A message \in CheckedAddComplexInstrumentRequest :
        LET read == DecodeAddComplexInstrumentRequest(EncodeAddComplexInstrumentRequest(message))
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

(* Every Add Flexible Instrument Request decodes back to what was encoded, and leaves nothing over *)
RoundTripAddFlexibleInstrumentRequest ==
    \A message \in CheckedAddFlexibleInstrumentRequest :
        LET read == DecodeAddFlexibleInstrumentRequest(EncodeAddFlexibleInstrumentRequest(message))
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

(* Every Approve Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripApproveTesTradeRequest ==
    \A message \in CheckedApproveTesTradeRequest :
        LET read == DecodeApproveTesTradeRequest(EncodeApproveTesTradeRequest(message))
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

(* Every Cross Request decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossRequest ==
    \A message \in CheckedCrossRequest :
        LET read == DecodeCrossRequest(EncodeCrossRequest(message))
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

(* Every Delete All Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllOrderRequest ==
    \A message \in CheckedDeleteAllOrderRequest :
        LET read == DecodeDeleteAllOrderRequest(EncodeDeleteAllOrderRequest(message))
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

(* Every Delete All Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllQuoteRequest ==
    \A message \in CheckedDeleteAllQuoteRequest :
        LET read == DecodeDeleteAllQuoteRequest(EncodeDeleteAllQuoteRequest(message))
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

(* Every Delete Order Complex Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderComplexRequest ==
    \A message \in CheckedDeleteOrderComplexRequest :
        LET read == DecodeDeleteOrderComplexRequest(EncodeDeleteOrderComplexRequest(message))
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

(* Every Delete Order Single Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderSingleRequest ==
    \A message \in CheckedDeleteOrderSingleRequest :
        LET read == DecodeDeleteOrderSingleRequest(EncodeDeleteOrderSingleRequest(message))
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

(* Every Delete Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteTesTradeRequest ==
    \A message \in CheckedDeleteTesTradeRequest :
        LET read == DecodeDeleteTesTradeRequest(EncodeDeleteTesTradeRequest(message))
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

(* Every Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSideAllocGrpComp ==
    \A message \in CheckedSideAllocGrpComp :
        LET read == DecodeSideAllocGrpComp(EncodeSideAllocGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Event Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentEventGrpComp ==
    \A message \in CheckedInstrumentEventGrpComp :
        LET read == DecodeInstrumentEventGrpComp(EncodeInstrumentEventGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Attribute Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentAttributeGrpComp ==
    \A message \in CheckedInstrumentAttributeGrpComp :
        LET read == DecodeInstrumentAttributeGrpComp(EncodeInstrumentAttributeGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Stip Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingStipGrpComp ==
    \A message \in CheckedUnderlyingStipGrpComp :
        LET read == DecodeUnderlyingStipGrpComp(EncodeUnderlyingStipGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterTesTradeRequest ==
    \A message \in CheckedEnterTesTradeRequest :
        LET read == DecodeEnterTesTradeRequest(EncodeEnterTesTradeRequest(message))
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
RoundTripRequestHeaderComp12 ==
    \A message \in CheckedRequestHeaderComp12 :
        LET read == DecodeRequestHeaderComp12(EncodeRequestHeaderComp12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Inquire Enrichment Rule Id List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireEnrichmentRuleIdListRequest ==
    \A message \in CheckedInquireEnrichmentRuleIdListRequest :
        LET read == DecodeInquireEnrichmentRuleIdListRequest(EncodeInquireEnrichmentRuleIdListRequest(message))
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

(* Every Inquire Mm Parameter Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireMmParameterRequest ==
    \A message \in CheckedInquireMmParameterRequest :
        LET read == DecodeInquireMmParameterRequest(EncodeInquireMmParameterRequest(message))
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

(* Every Inquire Session List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireSessionListRequest ==
    \A message \in CheckedInquireSessionListRequest :
        LET read == DecodeInquireSessionListRequest(EncodeInquireSessionListRequest(message))
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

(* Every Inquire User Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireUserRequest ==
    \A message \in CheckedInquireUserRequest :
        LET read == DecodeInquireUserRequest(EncodeInquireUserRequest(message))
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

(* Every Logon Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequest ==
    \A message \in CheckedLogonRequest :
        LET read == DecodeLogonRequest(EncodeLogonRequest(message))
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

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
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

(* Every Mm Parameter Definition Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMmParameterDefinitionRequest ==
    \A message \in CheckedMmParameterDefinitionRequest :
        LET read == DecodeMmParameterDefinitionRequest(EncodeMmParameterDefinitionRequest(message))
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
RoundTripRequestHeaderComp20 ==
    \A message \in CheckedRequestHeaderComp20 :
        LET read == DecodeRequestHeaderComp20(EncodeRequestHeaderComp20(message))
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
RoundTripRequestHeaderComp21 ==
    \A message \in CheckedRequestHeaderComp21 :
        LET read == DecodeRequestHeaderComp21(EncodeRequestHeaderComp21(message))
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
RoundTripRequestHeaderComp22 ==
    \A message \in CheckedRequestHeaderComp22 :
        LET read == DecodeRequestHeaderComp22(EncodeRequestHeaderComp22(message))
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
RoundTripRequestHeaderComp23 ==
    \A message \in CheckedRequestHeaderComp23 :
        LET read == DecodeRequestHeaderComp23(EncodeRequestHeaderComp23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSideAllocGrpComp2 ==
    \A message \in CheckedSideAllocGrpComp2 :
        LET read == DecodeSideAllocGrpComp2(EncodeSideAllocGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyTesTradeRequest ==
    \A message \in CheckedModifyTesTradeRequest :
        LET read == DecodeModifyTesTradeRequest(EncodeModifyTesTradeRequest(message))
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
RoundTripRequestHeaderComp25 ==
    \A message \in CheckedRequestHeaderComp25 :
        LET read == DecodeRequestHeaderComp25(EncodeRequestHeaderComp25(message))
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
RoundTripRequestHeaderComp26 ==
    \A message \in CheckedRequestHeaderComp26 :
        LET read == DecodeRequestHeaderComp26(EncodeRequestHeaderComp26(message))
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
RoundTripRequestHeaderComp27 ==
    \A message \in CheckedRequestHeaderComp27 :
        LET read == DecodeRequestHeaderComp27(EncodeRequestHeaderComp27(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Activation Request decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteActivationRequest ==
    \A message \in CheckedQuoteActivationRequest :
        LET read == DecodeQuoteActivationRequest(EncodeQuoteActivationRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp28 ==
    \A message \in CheckedRequestHeaderComp28 :
        LET read == DecodeRequestHeaderComp28(EncodeRequestHeaderComp28(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqRequest ==
    \A message \in CheckedRfqRequest :
        LET read == DecodeRfqRequest(EncodeRfqRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp29 ==
    \A message \in CheckedRequestHeaderComp29 :
        LET read == DecodeRequestHeaderComp29(EncodeRequestHeaderComp29(message))
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
RoundTripRequestHeaderComp30 ==
    \A message \in CheckedRequestHeaderComp30 :
        LET read == DecodeRequestHeaderComp30(EncodeRequestHeaderComp30(message))
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
RoundTripRequestHeaderComp31 ==
    \A message \in CheckedRequestHeaderComp31 :
        LET read == DecodeRequestHeaderComp31(EncodeRequestHeaderComp31(message))
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
RoundTripRequestHeaderComp32 ==
    \A message \in CheckedRequestHeaderComp32 :
        LET read == DecodeRequestHeaderComp32(EncodeRequestHeaderComp32(message))
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
RoundTripRequestHeaderComp33 ==
    \A message \in CheckedRequestHeaderComp33 :
        LET read == DecodeRequestHeaderComp33(EncodeRequestHeaderComp33(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Side Alloc Ext Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSideAllocExtGrpComp ==
    \A message \in CheckedSideAllocExtGrpComp :
        LET read == DecodeSideAllocExtGrpComp(EncodeSideAllocExtGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Event Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentEventGrpComp2 ==
    \A message \in CheckedInstrumentEventGrpComp2 :
        LET read == DecodeInstrumentEventGrpComp2(EncodeInstrumentEventGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Attribute Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentAttributeGrpComp2 ==
    \A message \in CheckedInstrumentAttributeGrpComp2 :
        LET read == DecodeInstrumentAttributeGrpComp2(EncodeInstrumentAttributeGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Stip Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingStipGrpComp2 ==
    \A message \in CheckedUnderlyingStipGrpComp2 :
        LET read == DecodeUnderlyingStipGrpComp2(EncodeUnderlyingStipGrpComp2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Upload Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUploadTesTradeRequest ==
    \A message \in CheckedUploadTesTradeRequest :
        LET read == DecodeUploadTesTradeRequest(EncodeUploadTesTradeRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp34 ==
    \A message \in CheckedRequestHeaderComp34 :
        LET read == DecodeRequestHeaderComp34(EncodeRequestHeaderComp34(message))
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
RoundTripRequestHeaderComp35 ==
    \A message \in CheckedRequestHeaderComp35 :
        LET read == DecodeRequestHeaderComp35(EncodeRequestHeaderComp35(message))
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
