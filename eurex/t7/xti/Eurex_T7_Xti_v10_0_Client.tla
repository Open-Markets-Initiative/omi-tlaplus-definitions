--------------------- MODULE Eurex_T7_Xti_v10_0_Client ---------------------
(***************************************************************************)
(* Eurex Exchange Cash Enhanced Trading Interface v10.0                    *)
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
(* Note: Delete Order Single Request fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Delete Tes Trade Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Enter Tes Trade Request fills what is left of the frame Body Len  *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Heartbeat fills what is left of the frame Body Len states, which  *)
(* is what it is read from.                                                *)
(*                                                                         *)
(* Note: Inquire Enrichment Rule Id List Request fills what is left of the *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Inquire Session List Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Inquire User Request fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Issuer Security State Change Request fills what is left of the    *)
(* frame Body Len states, which is what it is read from.                   *)
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
(* Note: Modify Order Single Request fills what is left of the frame Body  *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Modify Order Single Short Request fills what is left of the frame *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Modify Tes Trade Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: New Order Single Request fills what is left of the frame Body Len *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: New Order Single Short Request fills what is left of the frame    *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Ping Request fills what is left of the frame Body Len states,     *)
(* which is what it is read from.                                          *)
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
(* Note: Single Quote Request fills what is left of the frame Body Len     *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: Specialist Rfq Reject Request fills what is left of the frame     *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Specialist Rfq Reply Request fills what is left of the frame Body *)
(* Len states, which is what it is read from.                              *)
(*                                                                         *)
(* Note: Specialist Security State Change Request fills what is left of    *)
(* the frame Body Len states, which is what it is read from.               *)
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
(* Note: Xetra En Light Enter Quote Request fills what is left of the      *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Xetra En Light Hit Quote Request fills what is left of the frame  *)
(* Body Len states, which is what it is read from.                         *)
(*                                                                         *)
(* Note: Xetra En Light Open Negotiation Request fills what is left of the *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Xetra En Light Quoting Status Request fills what is left of the   *)
(* frame Body Len states, which is what it is read from.                   *)
(*                                                                         *)
(* Note: Xetra En Light Update Negotiation Request fills what is left of   *)
(* the frame Body Len states, which is what it is read from.               *)
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
(* Approve Tes Trade Request: 154 bytes                                    *)
(***************************************************************************)

ApproveTesTradeRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp,
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      allocQty                                : Sample(8),
      packageId                               : Sample(4),
      allocId                                 : Sample(4),
      tesExecId                               : Sample(4),
      marketSegmentId                         : Sample(4),
      trdType                                 : Sample(2),
      tradingCapacity                         : Sample(1),
      tradeReportType                         : Sample(1),
      side                                    : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      valueCheckTypeQuantity                  : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      orderOrigination                        : Sample(1),
      tradeReportId                           : Sample(20),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText4                               : Sample(16),
      pad6                                    : Sample(6) ]

EncodeApproveTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp(message.requestHeaderComp)
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.allocQty
        \o message.packageId
        \o message.allocId
        \o message.tesExecId
        \o message.marketSegmentId
        \o message.trdType
        \o message.tradingCapacity
        \o message.tradeReportType
        \o message.side
        \o message.valueCheckTypeValue
        \o message.valueCheckTypeQuantity
        \o message.orderAttributeLiquidityProvision
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.orderOrigination
        \o message.tradeReportId
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.pad6

DecodeApproveTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET allocQty == ReadBytes(executingTrader.rest, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET packageId == ReadBytes(allocQty.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET allocId == ReadBytes(packageId.rest, 4) IN IF ~allocId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(allocId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(tesExecId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET trdType == ReadBytes(marketSegmentId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(trdType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(tradingCapacity.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET side == ReadBytes(tradeReportType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(side.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(orderOrigination.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(tradeReportId.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyExecutingTrader.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET pad6 == ReadBytes(freeText4.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         allocQty                                |-> allocQty.value,
         packageId                               |-> packageId.value,
         allocId                                 |-> allocId.value,
         tesExecId                               |-> tesExecId.value,
         marketSegmentId                         |-> marketSegmentId.value,
         trdType                                 |-> trdType.value,
         tradingCapacity                         |-> tradingCapacity.value,
         tradeReportType                         |-> tradeReportType.value,
         side                                    |-> side.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         valueCheckTypeQuantity                  |-> valueCheckTypeQuantity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         orderOrigination                        |-> orderOrigination.value,
         tradeReportId                           |-> tradeReportId.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText4                               |-> freeText4.value,
         pad6                                    |-> pad6.value ], pad6.rest)

ZeroApproveTesTradeRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp,
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      allocQty                                |-> [i \in 1 .. 8 |-> 0],
      packageId                               |-> [i \in 1 .. 4 |-> 0],
      allocId                                 |-> [i \in 1 .. 4 |-> 0],
      tesExecId                               |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      trdType                                 |-> [i \in 1 .. 2 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      tradeReportType                         |-> [i \in 1 .. 1 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity                  |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      tradeReportId                           |-> [i \in 1 .. 20 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText4                               |-> [i \in 1 .. 16 |-> 0],
      pad6                                    |-> [i \in 1 .. 6 |-> 0] ]

(* Approve Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedApproveTesTradeRequest ==
    { ZeroApproveTesTradeRequest }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.allocId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroApproveTesTradeRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Cross Request: 42 bytes                                                 *)
(***************************************************************************)

CrossRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp2,
      securityId        : Sample(8),
      orderQty          : Sample(8),
      marketSegmentId   : Sample(4),
      pad4              : Sample(4) ]

EncodeCrossRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp2(message.requestHeaderComp)
        \o message.securityId
        \o message.orderQty
        \o message.marketSegmentId
        \o message.pad4

DecodeCrossRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp2(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(marketSegmentId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         securityId        |-> securityId.value,
         orderQty          |-> orderQty.value,
         marketSegmentId   |-> marketSegmentId.value,
         pad4              |-> pad4.value ], pad4.rest)

ZeroCrossRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp2,
      securityId        |-> [i \in 1 .. 8 |-> 0],
      orderQty          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Cross Request at zero, then each field in turn at the values it is checked at *)
CheckedCrossRequest ==
    { ZeroCrossRequest }
        \cup { [ZeroCrossRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroCrossRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp2 }
        \cup { [ZeroCrossRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroCrossRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

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
(* Delete All Order Request: 66 bytes                                      *)
(***************************************************************************)

DeleteAllOrderRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp3,
      securityId                              : Sample(8),
      price                                   : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      targetPartyIdExecutingTrader            : Sample(4),
      side                                    : Sample(1),
      orderOrigination                        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1) ]

EncodeDeleteAllOrderRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp3(message.requestHeaderComp)
        \o message.securityId
        \o message.price
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.targetPartyIdExecutingTrader
        \o message.side
        \o message.orderOrigination
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier

DecodeDeleteAllOrderRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp3(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(price.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET targetPartyIdExecutingTrader == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~targetPartyIdExecutingTrader.ok THEN Fail ELSE
    LET side == ReadBytes(targetPartyIdExecutingTrader.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(side.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         securityId                              |-> securityId.value,
         price                                   |-> price.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         targetPartyIdExecutingTrader            |-> targetPartyIdExecutingTrader.value,
         side                                    |-> side.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value ], executingTraderQualifier.rest)

ZeroDeleteAllOrderRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp3,
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdExecutingTrader            |-> [i \in 1 .. 4 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0] ]

(* Delete All Order Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllOrderRequest ==
    { ZeroDeleteAllOrderRequest }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp3 }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.targetPartyIdExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllOrderRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }

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
(* Delete All Quote Request: 50 bytes                                      *)
(***************************************************************************)

DeleteAllQuoteRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp4,
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      pad6                                    : Sample(6) ]

EncodeDeleteAllQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp4(message.requestHeaderComp)
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.pad6

DecodeDeleteAllQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp4(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(requestHeaderComp.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(targetPartyIdSessionId.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET pad6 == ReadBytes(executingTraderQualifier.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         pad6                                    |-> pad6.value ], pad6.rest)

ZeroDeleteAllQuoteRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp4,
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      pad6                                    |-> [i \in 1 .. 6 |-> 0] ]

(* Delete All Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteAllQuoteRequest ==
    { ZeroDeleteAllQuoteRequest }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp4 }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteAllQuoteRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Delete Order Single Request: 114 bytes                                  *)
(***************************************************************************)

DeleteOrderSingleRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp5,
      orderId                                 : Sample(8),
      clOrdId                                 : Sample(8),
      origClOrdId                             : Sample(8),
      securityId                              : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      orderOrigination                        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      fixClOrdId                              : Sample(20),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      pad6                                    : Sample(6) ]

EncodeDeleteOrderSingleRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp5(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.orderOrigination
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.fixClOrdId
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad6

DecodeDeleteOrderSingleRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp5(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(securityId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(targetPartyIdSessionId.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(executingTraderQualifier.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(fixClOrdId.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyExecutingTrader.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         orderId                                 |-> orderId.value,
         clOrdId                                 |-> clOrdId.value,
         origClOrdId                             |-> origClOrdId.value,
         securityId                              |-> securityId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         fixClOrdId                              |-> fixClOrdId.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         pad6                                    |-> pad6.value ], pad6.rest)

ZeroDeleteOrderSingleRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp5,
      orderId                                 |-> [i \in 1 .. 8 |-> 0],
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                             |-> [i \in 1 .. 8 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      fixClOrdId                              |-> [i \in 1 .. 20 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      pad6                                    |-> [i \in 1 .. 6 |-> 0] ]

(* Delete Order Single Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderSingleRequest ==
    { ZeroDeleteOrderSingleRequest }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp5 }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroDeleteOrderSingleRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Delete Tes Trade Request: 58 bytes                                      *)
(***************************************************************************)

DeleteTesTradeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp6,
      packageId         : Sample(4),
      marketSegmentId   : Sample(4),
      tesExecId         : Sample(4),
      trdType           : Sample(2),
      tradeReportType   : Sample(1),
      tradeReportId     : Sample(20),
      pad5              : Sample(5) ]

EncodeDeleteTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp6(message.requestHeaderComp)
        \o message.packageId
        \o message.marketSegmentId
        \o message.tesExecId
        \o message.trdType
        \o message.tradeReportType
        \o message.tradeReportId
        \o message.pad5

DecodeDeleteTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp6(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET packageId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(packageId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(marketSegmentId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET trdType == ReadBytes(tesExecId.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportType.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad5 == ReadBytes(tradeReportId.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         packageId         |-> packageId.value,
         marketSegmentId   |-> marketSegmentId.value,
         tesExecId         |-> tesExecId.value,
         trdType           |-> trdType.value,
         tradeReportType   |-> tradeReportType.value,
         tradeReportId     |-> tradeReportId.value,
         pad5              |-> pad5.value ], pad5.rest)

ZeroDeleteTesTradeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp6,
      packageId         |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      tesExecId         |-> [i \in 1 .. 4 |-> 0],
      trdType           |-> [i \in 1 .. 2 |-> 0],
      tradeReportType   |-> [i \in 1 .. 1 |-> 0],
      tradeReportId     |-> [i \in 1 .. 20 |-> 0],
      pad5              |-> [i \in 1 .. 5 |-> 0] ]

(* Delete Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedDeleteTesTradeRequest ==
    { ZeroDeleteTesTradeRequest }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp6 }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroDeleteTesTradeRequest EXCEPT !.pad5 = one] : one \in Sample(5) }

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
(* Side Alloc Grp Comp: 32 bytes                                           *)
(***************************************************************************)

SideAllocGrpComp ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      tesEnrichmentRuleId  : Sample(4),
      side                 : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeSideAllocGrpComp(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.tesEnrichmentRuleId
        \o message.side
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeSideAllocGrpComp(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET tesEnrichmentRuleId == ReadBytes(individualAllocId.rest, 4) IN IF ~tesEnrichmentRuleId.ok THEN Fail ELSE
    LET side == ReadBytes(tesEnrichmentRuleId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         tesEnrichmentRuleId  |-> tesEnrichmentRuleId.value,
         side                 |-> side.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroSideAllocGrpComp ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      tesEnrichmentRuleId  |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideAllocGrpComp ==
    { ZeroSideAllocGrpComp }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp EXCEPT !.tesEnrichmentRuleId = one] : one \in Sample(4) }
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
(* Enter Tes Trade Request                                                 *)
(***************************************************************************)

EnterTesTradeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp7,
      securityId        : Sample(8),
      lastPx            : Sample(8),
      transBkdTime      : Sample(8),
      settlCurrFxRate   : Sample(8),
      marketSegmentId   : Sample(4),
      settlDate         : Sample(4),
      trdType           : Sample(2),
      tradeReportType   : Sample(1),
      tradeReportText   : Sample(20),
      tradeReportId     : Sample(20),
      pad4              : Sample(4),
      sideAllocGrpComp  : SampleLists(OneSideAllocGrpComp) ]

EncodeEnterTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp7(message.requestHeaderComp)
        \o message.securityId
        \o message.lastPx
        \o message.transBkdTime
        \o message.settlCurrFxRate
        \o message.marketSegmentId
        \o message.settlDate
        \o message.trdType
        \o message.tradeReportType
        \o EncodeUIntBE(Len(message.sideAllocGrpComp), 1)
        \o message.tradeReportText
        \o message.tradeReportId
        \o message.pad4
        \o EncodeSideAllocGrpCompList(message.sideAllocGrpComp)

DecodeEnterTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp7(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(securityId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET settlCurrFxRate == ReadBytes(transBkdTime.rest, 8) IN IF ~settlCurrFxRate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(settlCurrFxRate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET settlDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET trdType == ReadBytes(settlDate.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET noSideAllocs == ReadUIntBE(tradeReportType.rest, 1) IN IF ~noSideAllocs.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(noSideAllocs.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(tradeReportId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET sideAllocGrpComp == ReadSideAllocGrpCompList(pad4.rest, noSideAllocs.value) IN IF ~sideAllocGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         securityId        |-> securityId.value,
         lastPx            |-> lastPx.value,
         transBkdTime      |-> transBkdTime.value,
         settlCurrFxRate   |-> settlCurrFxRate.value,
         marketSegmentId   |-> marketSegmentId.value,
         settlDate         |-> settlDate.value,
         trdType           |-> trdType.value,
         tradeReportType   |-> tradeReportType.value,
         tradeReportText   |-> tradeReportText.value,
         tradeReportId     |-> tradeReportId.value,
         pad4              |-> pad4.value,
         sideAllocGrpComp  |-> sideAllocGrpComp.value ], sideAllocGrpComp.rest)

ZeroEnterTesTradeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp7,
      securityId        |-> [i \in 1 .. 8 |-> 0],
      lastPx            |-> [i \in 1 .. 8 |-> 0],
      transBkdTime      |-> [i \in 1 .. 8 |-> 0],
      settlCurrFxRate   |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      settlDate         |-> [i \in 1 .. 4 |-> 0],
      trdType           |-> [i \in 1 .. 2 |-> 0],
      tradeReportType   |-> [i \in 1 .. 1 |-> 0],
      tradeReportText   |-> [i \in 1 .. 20 |-> 0],
      tradeReportId     |-> [i \in 1 .. 20 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0],
      sideAllocGrpComp  |-> << >> ]

(* Enter Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedEnterTesTradeRequest ==
    { ZeroEnterTesTradeRequest }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp7 }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.settlCurrFxRate = one] : one \in Sample(8) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroEnterTesTradeRequest EXCEPT !.sideAllocGrpComp = one] : one \in SampleLists(OneSideAllocGrpComp) }

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
(* Inquire Enrichment Rule Id List Request: 34 bytes                       *)
(***************************************************************************)

InquireEnrichmentRuleIdListRequest ==
    [ networkMsgId        : Sample(8),
      pad2                : Sample(2),
      requestHeaderComp   : RequestHeaderComp8,
      lastEntityProcessed : Sample(16) ]

EncodeInquireEnrichmentRuleIdListRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp8(message.requestHeaderComp)
        \o message.lastEntityProcessed

DecodeInquireEnrichmentRuleIdListRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp8(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET lastEntityProcessed == ReadBytes(requestHeaderComp.rest, 16) IN IF ~lastEntityProcessed.ok THEN Fail ELSE
    Ok([ networkMsgId        |-> networkMsgId.value,
         pad2                |-> pad2.value,
         requestHeaderComp   |-> requestHeaderComp.value,
         lastEntityProcessed |-> lastEntityProcessed.value ], lastEntityProcessed.rest)

ZeroInquireEnrichmentRuleIdListRequest ==
    [ networkMsgId        |-> [i \in 1 .. 8 |-> 0],
      pad2                |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp   |-> ZeroRequestHeaderComp8,
      lastEntityProcessed |-> [i \in 1 .. 16 |-> 0] ]

(* Inquire Enrichment Rule Id List Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireEnrichmentRuleIdListRequest ==
    { ZeroInquireEnrichmentRuleIdListRequest }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp8 }
        \cup { [ZeroInquireEnrichmentRuleIdListRequest EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }

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
(* Inquire Session List Request: 18 bytes                                  *)
(***************************************************************************)

InquireSessionListRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp9 ]

EncodeInquireSessionListRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp9(message.requestHeaderComp)

DecodeInquireSessionListRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp9(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroInquireSessionListRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp9 ]

(* Inquire Session List Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireSessionListRequest ==
    { ZeroInquireSessionListRequest }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireSessionListRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp9 }

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
(* Inquire User Request: 34 bytes                                          *)
(***************************************************************************)

InquireUserRequest ==
    [ networkMsgId        : Sample(8),
      pad2                : Sample(2),
      requestHeaderComp   : RequestHeaderComp10,
      lastEntityProcessed : Sample(16) ]

EncodeInquireUserRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp10(message.requestHeaderComp)
        \o message.lastEntityProcessed

DecodeInquireUserRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp10(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET lastEntityProcessed == ReadBytes(requestHeaderComp.rest, 16) IN IF ~lastEntityProcessed.ok THEN Fail ELSE
    Ok([ networkMsgId        |-> networkMsgId.value,
         pad2                |-> pad2.value,
         requestHeaderComp   |-> requestHeaderComp.value,
         lastEntityProcessed |-> lastEntityProcessed.value ], lastEntityProcessed.rest)

ZeroInquireUserRequest ==
    [ networkMsgId        |-> [i \in 1 .. 8 |-> 0],
      pad2                |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp   |-> ZeroRequestHeaderComp10,
      lastEntityProcessed |-> [i \in 1 .. 16 |-> 0] ]

(* Inquire User Request at zero, then each field in turn at the values it is checked at *)
CheckedInquireUserRequest ==
    { ZeroInquireUserRequest }
        \cup { [ZeroInquireUserRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroInquireUserRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroInquireUserRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp10 }
        \cup { [ZeroInquireUserRequest EXCEPT !.lastEntityProcessed = one] : one \in Sample(16) }

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
(* Security Status Event Grp Comp: 16 bytes                                *)
(***************************************************************************)

SecurityStatusEventGrpComp ==
    [ eventPx   : Sample(8),
      eventDate : Sample(4),
      eventType : Sample(1),
      pad3      : Sample(3) ]

EncodeSecurityStatusEventGrpComp(message) ==
    message.eventPx
        \o message.eventDate
        \o message.eventType
        \o message.pad3

DecodeSecurityStatusEventGrpComp(bytes) ==
    LET eventPx == ReadBytes(bytes, 8) IN IF ~eventPx.ok THEN Fail ELSE
    LET eventDate == ReadBytes(eventPx.rest, 4) IN IF ~eventDate.ok THEN Fail ELSE
    LET eventType == ReadBytes(eventDate.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET pad3 == ReadBytes(eventType.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ eventPx   |-> eventPx.value,
         eventDate |-> eventDate.value,
         eventType |-> eventType.value,
         pad3      |-> pad3.value ], pad3.rest)

ZeroSecurityStatusEventGrpComp ==
    [ eventPx   |-> [i \in 1 .. 8 |-> 0],
      eventDate |-> [i \in 1 .. 4 |-> 0],
      eventType |-> [i \in 1 .. 1 |-> 0],
      pad3      |-> [i \in 1 .. 3 |-> 0] ]

(* Security Status Event Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusEventGrpComp ==
    { ZeroSecurityStatusEventGrpComp }
        \cup { [ZeroSecurityStatusEventGrpComp EXCEPT !.eventPx = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusEventGrpComp EXCEPT !.eventDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusEventGrpComp EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusEventGrpComp EXCEPT !.pad3 = one] : one \in Sample(3) }

(* A run of Security Status Event Grp Comp, written one after another *)
RECURSIVE EncodeSecurityStatusEventGrpCompList(_)
EncodeSecurityStatusEventGrpCompList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityStatusEventGrpComp(Head(messages)) \o EncodeSecurityStatusEventGrpCompList(Tail(messages))

(* As many Security Status Event Grp Comp as the field that counts them says *)
RECURSIVE ReadSecurityStatusEventGrpCompList(_, _)
ReadSecurityStatusEventGrpCompList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityStatusEventGrpComp(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityStatusEventGrpCompList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Status Event Grp Comp of each kind, for the lists that carry them *)
OneSecurityStatusEventGrpComp == { ZeroSecurityStatusEventGrpComp }

(***************************************************************************)
(* Issuer Security State Change Request                                    *)
(***************************************************************************)

IssuerSecurityStateChangeRequest ==
    [ networkMsgId               : Sample(8),
      pad2                       : Sample(2),
      requestHeaderComp          : RequestHeaderComp11,
      securityId                 : Sample(8),
      transactTime               : Sample(8),
      marketSegmentId            : Sample(4),
      securityStatus             : Sample(1),
      soldOutIndicator           : Sample(1),
      pad1                       : Sample(1),
      securityStatusEventGrpComp : SampleLists(OneSecurityStatusEventGrpComp) ]

EncodeIssuerSecurityStateChangeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp11(message.requestHeaderComp)
        \o message.securityId
        \o message.transactTime
        \o message.marketSegmentId
        \o EncodeUIntBE(Len(message.securityStatusEventGrpComp), 1)
        \o message.securityStatus
        \o message.soldOutIndicator
        \o message.pad1
        \o EncodeSecurityStatusEventGrpCompList(message.securityStatusEventGrpComp)

DecodeIssuerSecurityStateChangeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp11(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET transactTime == ReadBytes(securityId.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(transactTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET noEvents == ReadUIntBE(marketSegmentId.rest, 1) IN IF ~noEvents.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(noEvents.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET soldOutIndicator == ReadBytes(securityStatus.rest, 1) IN IF ~soldOutIndicator.ok THEN Fail ELSE
    LET pad1 == ReadBytes(soldOutIndicator.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET securityStatusEventGrpComp == ReadSecurityStatusEventGrpCompList(pad1.rest, noEvents.value) IN IF ~securityStatusEventGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId               |-> networkMsgId.value,
         pad2                       |-> pad2.value,
         requestHeaderComp          |-> requestHeaderComp.value,
         securityId                 |-> securityId.value,
         transactTime               |-> transactTime.value,
         marketSegmentId            |-> marketSegmentId.value,
         securityStatus             |-> securityStatus.value,
         soldOutIndicator           |-> soldOutIndicator.value,
         pad1                       |-> pad1.value,
         securityStatusEventGrpComp |-> securityStatusEventGrpComp.value ], securityStatusEventGrpComp.rest)

ZeroIssuerSecurityStateChangeRequest ==
    [ networkMsgId               |-> [i \in 1 .. 8 |-> 0],
      pad2                       |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp          |-> ZeroRequestHeaderComp11,
      securityId                 |-> [i \in 1 .. 8 |-> 0],
      transactTime               |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId            |-> [i \in 1 .. 4 |-> 0],
      securityStatus             |-> [i \in 1 .. 1 |-> 0],
      soldOutIndicator           |-> [i \in 1 .. 1 |-> 0],
      pad1                       |-> [i \in 1 .. 1 |-> 0],
      securityStatusEventGrpComp |-> << >> ]

(* Issuer Security State Change Request at zero, then each field in turn at the values it is checked at *)
CheckedIssuerSecurityStateChangeRequest ==
    { ZeroIssuerSecurityStateChangeRequest }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp11 }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.soldOutIndicator = one] : one \in Sample(1) }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroIssuerSecurityStateChangeRequest EXCEPT !.securityStatusEventGrpComp = one] : one \in SampleLists(OneSecurityStatusEventGrpComp) }

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
(* Logon Request: 274 bytes                                                *)
(***************************************************************************)

LogonRequest ==
    [ networkMsgId             : Sample(8),
      pad2                     : Sample(2),
      requestHeaderComp        : RequestHeaderComp12,
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
        \o EncodeRequestHeaderComp12(message.requestHeaderComp)
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
    LET requestHeaderComp == DecodeRequestHeaderComp12(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp        |-> ZeroRequestHeaderComp12,
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
        \cup { [ZeroLogonRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp12 }
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
(* Logout Request: 18 bytes                                                *)
(***************************************************************************)

LogoutRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp13 ]

EncodeLogoutRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp13(message.requestHeaderComp)

DecodeLogoutRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp13(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value ], requestHeaderComp.rest)

ZeroLogoutRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp13 ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroLogoutRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroLogoutRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp13 }

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
(* Quote Entry Grp Comp: 40 bytes                                          *)
(***************************************************************************)

QuoteEntryGrpComp ==
    [ securityId : Sample(8),
      bidPx      : Sample(8),
      bidSize    : Sample(8),
      offerPx    : Sample(8),
      offerSize  : Sample(8) ]

EncodeQuoteEntryGrpComp(message) ==
    message.securityId
        \o message.bidPx
        \o message.bidSize
        \o message.offerPx
        \o message.offerSize

DecodeQuoteEntryGrpComp(bytes) ==
    LET securityId == ReadBytes(bytes, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidSize.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPx.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         bidPx      |-> bidPx.value,
         bidSize    |-> bidSize.value,
         offerPx    |-> offerPx.value,
         offerSize  |-> offerSize.value ], offerSize.rest)

ZeroQuoteEntryGrpComp ==
    [ securityId |-> [i \in 1 .. 8 |-> 0],
      bidPx      |-> [i \in 1 .. 8 |-> 0],
      bidSize    |-> [i \in 1 .. 8 |-> 0],
      offerPx    |-> [i \in 1 .. 8 |-> 0],
      offerSize  |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Entry Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEntryGrpComp ==
    { ZeroQuoteEntryGrpComp }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntryGrpComp EXCEPT !.offerSize = one] : one \in Sample(8) }

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
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp14,
      quoteId                                 : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      matchInstCrossId                        : Sample(4),
      enrichmentRuleId                        : Sample(2),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      valueCheckTypeQuantity                  : Sample(1),
      quoteSizeType                           : Sample(1),
      quoteType                               : Sample(1),
      tradingCapacity                         : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      pad4                                    : Sample(4),
      quoteEntryGrpComp                       : SampleLists(OneQuoteEntryGrpComp) ]

EncodeMassQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp14(message.requestHeaderComp)
        \o message.quoteId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.matchInstCrossId
        \o message.enrichmentRuleId
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.valueCheckTypeQuantity
        \o message.quoteSizeType
        \o message.quoteType
        \o message.tradingCapacity
        \o message.orderAttributeLiquidityProvision
        \o EncodeUIntBE(Len(message.quoteEntryGrpComp), 1)
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.pad4
        \o EncodeQuoteEntryGrpCompList(message.quoteEntryGrpComp)

DecodeMassQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp14(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(quoteId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(marketSegmentId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(matchInstCrossId.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET quoteSizeType == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~quoteSizeType.ok THEN Fail ELSE
    LET quoteType == ReadBytes(quoteSizeType.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(quoteType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET noQuoteEntries == ReadUIntBE(orderAttributeLiquidityProvision.rest, 1) IN IF ~noQuoteEntries.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(noQuoteEntries.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET pad4 == ReadBytes(executingTraderQualifier.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET quoteEntryGrpComp == ReadQuoteEntryGrpCompList(pad4.rest, noQuoteEntries.value) IN IF ~quoteEntryGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         quoteId                                 |-> quoteId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         enrichmentRuleId                        |-> enrichmentRuleId.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         valueCheckTypeQuantity                  |-> valueCheckTypeQuantity.value,
         quoteSizeType                           |-> quoteSizeType.value,
         quoteType                               |-> quoteType.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         pad4                                    |-> pad4.value,
         quoteEntryGrpComp                       |-> quoteEntryGrpComp.value ], quoteEntryGrpComp.rest)

ZeroMassQuoteRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp14,
      quoteId                                 |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      enrichmentRuleId                        |-> [i \in 1 .. 2 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity                  |-> [i \in 1 .. 1 |-> 0],
      quoteSizeType                           |-> [i \in 1 .. 1 |-> 0],
      quoteType                               |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      pad4                                    |-> [i \in 1 .. 4 |-> 0],
      quoteEntryGrpComp                       |-> << >> ]

(* Mass Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedMassQuoteRequest ==
    { ZeroMassQuoteRequest }
        \cup { [ZeroMassQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp14 }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteSizeType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroMassQuoteRequest EXCEPT !.quoteEntryGrpComp = one] : one \in SampleLists(OneQuoteEntryGrpComp) }

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
(* Modify Order Single Request: 250 bytes                                  *)
(***************************************************************************)

ModifyOrderSingleRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp15,
      orderId                                 : Sample(8),
      clOrdId                                 : Sample(8),
      origClOrdId                             : Sample(8),
      securityId                              : Sample(8),
      price                                   : Sample(8),
      orderQty                                : Sample(8),
      displayQty                              : Sample(8),
      displayLowQty                           : Sample(8),
      displayHighQty                          : Sample(8),
      stopPx                                  : Sample(8),
      volumeDiscoveryPrice                    : Sample(8),
      pegOffsetValueAbs                       : Sample(8),
      pegOffsetValuePct                       : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      expireDate                              : Sample(4),
      marketSegmentId                         : Sample(4),
      matchInstCrossId                        : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      applSeqIndicator                        : Sample(1),
      side                                    : Sample(1),
      ordType                                 : Sample(1),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      valueCheckTypeQuantity                  : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      timeInForce                             : Sample(1),
      execInst                                : Sample(1),
      tradingSessionSubId                     : Sample(1),
      stopPxIndicator                         : Sample(1),
      tradingCapacity                         : Sample(1),
      orderOrigination                        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      ownershipIndicator                      : Sample(1),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText4                               : Sample(16),
      fixClOrdId                              : Sample(20),
      pad1                                    : Sample(1) ]

EncodeModifyOrderSingleRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp15(message.requestHeaderComp)
        \o message.orderId
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.price
        \o message.orderQty
        \o message.displayQty
        \o message.displayLowQty
        \o message.displayHighQty
        \o message.stopPx
        \o message.volumeDiscoveryPrice
        \o message.pegOffsetValueAbs
        \o message.pegOffsetValuePct
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.expireDate
        \o message.marketSegmentId
        \o message.matchInstCrossId
        \o message.targetPartyIdSessionId
        \o message.applSeqIndicator
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.valueCheckTypeQuantity
        \o message.orderAttributeLiquidityProvision
        \o message.timeInForce
        \o message.execInst
        \o message.tradingSessionSubId
        \o message.stopPxIndicator
        \o message.tradingCapacity
        \o message.orderOrigination
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.ownershipIndicator
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.fixClOrdId
        \o message.pad1

DecodeModifyOrderSingleRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp15(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET orderId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(orderQty.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayLowQty == ReadBytes(displayQty.rest, 8) IN IF ~displayLowQty.ok THEN Fail ELSE
    LET displayHighQty == ReadBytes(displayLowQty.rest, 8) IN IF ~displayHighQty.ok THEN Fail ELSE
    LET stopPx == ReadBytes(displayHighQty.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET volumeDiscoveryPrice == ReadBytes(stopPx.rest, 8) IN IF ~volumeDiscoveryPrice.ok THEN Fail ELSE
    LET pegOffsetValueAbs == ReadBytes(volumeDiscoveryPrice.rest, 8) IN IF ~pegOffsetValueAbs.ok THEN Fail ELSE
    LET pegOffsetValuePct == ReadBytes(pegOffsetValueAbs.rest, 8) IN IF ~pegOffsetValuePct.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(pegOffsetValuePct.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET expireDate == ReadBytes(executingTrader.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(expireDate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(marketSegmentId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(matchInstCrossId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(targetPartyIdSessionId.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(applSeqIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(execInst.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET stopPxIndicator == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~stopPxIndicator.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(stopPxIndicator.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET ownershipIndicator == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~ownershipIndicator.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(ownershipIndicator.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyExecutingTrader.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(freeText4.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET pad1 == ReadBytes(fixClOrdId.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         orderId                                 |-> orderId.value,
         clOrdId                                 |-> clOrdId.value,
         origClOrdId                             |-> origClOrdId.value,
         securityId                              |-> securityId.value,
         price                                   |-> price.value,
         orderQty                                |-> orderQty.value,
         displayQty                              |-> displayQty.value,
         displayLowQty                           |-> displayLowQty.value,
         displayHighQty                          |-> displayHighQty.value,
         stopPx                                  |-> stopPx.value,
         volumeDiscoveryPrice                    |-> volumeDiscoveryPrice.value,
         pegOffsetValueAbs                       |-> pegOffsetValueAbs.value,
         pegOffsetValuePct                       |-> pegOffsetValuePct.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         expireDate                              |-> expireDate.value,
         marketSegmentId                         |-> marketSegmentId.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         applSeqIndicator                        |-> applSeqIndicator.value,
         side                                    |-> side.value,
         ordType                                 |-> ordType.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         valueCheckTypeQuantity                  |-> valueCheckTypeQuantity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         timeInForce                             |-> timeInForce.value,
         execInst                                |-> execInst.value,
         tradingSessionSubId                     |-> tradingSessionSubId.value,
         stopPxIndicator                         |-> stopPxIndicator.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         ownershipIndicator                      |-> ownershipIndicator.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText4                               |-> freeText4.value,
         fixClOrdId                              |-> fixClOrdId.value,
         pad1                                    |-> pad1.value ], pad1.rest)

ZeroModifyOrderSingleRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp15,
      orderId                                 |-> [i \in 1 .. 8 |-> 0],
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                             |-> [i \in 1 .. 8 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      displayQty                              |-> [i \in 1 .. 8 |-> 0],
      displayLowQty                           |-> [i \in 1 .. 8 |-> 0],
      displayHighQty                          |-> [i \in 1 .. 8 |-> 0],
      stopPx                                  |-> [i \in 1 .. 8 |-> 0],
      volumeDiscoveryPrice                    |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValueAbs                       |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValuePct                       |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      expireDate                              |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      applSeqIndicator                        |-> [i \in 1 .. 1 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      ordType                                 |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity                  |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      timeInForce                             |-> [i \in 1 .. 1 |-> 0],
      execInst                                |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId                     |-> [i \in 1 .. 1 |-> 0],
      stopPxIndicator                         |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      ownershipIndicator                      |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText4                               |-> [i \in 1 .. 16 |-> 0],
      fixClOrdId                              |-> [i \in 1 .. 20 |-> 0],
      pad1                                    |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Single Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderSingleRequest ==
    { ZeroModifyOrderSingleRequest }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp15 }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.displayLowQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.displayHighQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.volumeDiscoveryPrice = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.pegOffsetValueAbs = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.pegOffsetValuePct = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.stopPxIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.ownershipIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroModifyOrderSingleRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

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
(* Modify Order Single Short Request: 106 bytes                            *)
(***************************************************************************)

ModifyOrderSingleShortRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp16,
      clOrdId                                 : Sample(8),
      origClOrdId                             : Sample(8),
      securityId                              : Sample(8),
      price                                   : Sample(8),
      orderQty                                : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      matchInstCrossId                        : Sample(4),
      enrichmentRuleId                        : Sample(2),
      side                                    : Sample(1),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      valueCheckTypeQuantity                  : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      timeInForce                             : Sample(1),
      applSeqIndicator                        : Sample(1),
      execInst                                : Sample(1),
      tradingCapacity                         : Sample(1),
      orderOrigination                        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      pad6                                    : Sample(6) ]

EncodeModifyOrderSingleShortRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp16(message.requestHeaderComp)
        \o message.clOrdId
        \o message.origClOrdId
        \o message.securityId
        \o message.price
        \o message.orderQty
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.matchInstCrossId
        \o message.enrichmentRuleId
        \o message.side
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.valueCheckTypeQuantity
        \o message.orderAttributeLiquidityProvision
        \o message.timeInForce
        \o message.applSeqIndicator
        \o message.execInst
        \o message.tradingCapacity
        \o message.orderOrigination
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.pad6

DecodeModifyOrderSingleShortRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp16(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(clOrdId.rest, 8) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(origClOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(orderQty.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(executingTrader.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(matchInstCrossId.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET side == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(side.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET execInst == ReadBytes(applSeqIndicator.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET pad6 == ReadBytes(executingTraderQualifier.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         clOrdId                                 |-> clOrdId.value,
         origClOrdId                             |-> origClOrdId.value,
         securityId                              |-> securityId.value,
         price                                   |-> price.value,
         orderQty                                |-> orderQty.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         enrichmentRuleId                        |-> enrichmentRuleId.value,
         side                                    |-> side.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         valueCheckTypeQuantity                  |-> valueCheckTypeQuantity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         timeInForce                             |-> timeInForce.value,
         applSeqIndicator                        |-> applSeqIndicator.value,
         execInst                                |-> execInst.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         pad6                                    |-> pad6.value ], pad6.rest)

ZeroModifyOrderSingleShortRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp16,
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      origClOrdId                             |-> [i \in 1 .. 8 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      enrichmentRuleId                        |-> [i \in 1 .. 2 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity                  |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      timeInForce                             |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator                        |-> [i \in 1 .. 1 |-> 0],
      execInst                                |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      pad6                                    |-> [i \in 1 .. 6 |-> 0] ]

(* Modify Order Single Short Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderSingleShortRequest ==
    { ZeroModifyOrderSingleShortRequest }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp16 }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.origClOrdId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderSingleShortRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Side Alloc Grp Comp: 32 bytes                                           *)
(***************************************************************************)

SideAllocGrpComp2 ==
    [ allocQty             : Sample(8),
      individualAllocId    : Sample(4),
      tesEnrichmentRuleId  : Sample(4),
      side                 : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeSideAllocGrpComp2(message) ==
    message.allocQty
        \o message.individualAllocId
        \o message.tesEnrichmentRuleId
        \o message.side
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeSideAllocGrpComp2(bytes) ==
    LET allocQty == ReadBytes(bytes, 8) IN IF ~allocQty.ok THEN Fail ELSE
    LET individualAllocId == ReadBytes(allocQty.rest, 4) IN IF ~individualAllocId.ok THEN Fail ELSE
    LET tesEnrichmentRuleId == ReadBytes(individualAllocId.rest, 4) IN IF ~tesEnrichmentRuleId.ok THEN Fail ELSE
    LET side == ReadBytes(tesEnrichmentRuleId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(side.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ allocQty             |-> allocQty.value,
         individualAllocId    |-> individualAllocId.value,
         tesEnrichmentRuleId  |-> tesEnrichmentRuleId.value,
         side                 |-> side.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroSideAllocGrpComp2 ==
    [ allocQty             |-> [i \in 1 .. 8 |-> 0],
      individualAllocId    |-> [i \in 1 .. 4 |-> 0],
      tesEnrichmentRuleId  |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Side Alloc Grp Comp at zero, then each field in turn at the values it is checked at *)
CheckedSideAllocGrpComp2 ==
    { ZeroSideAllocGrpComp2 }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.allocQty = one] : one \in Sample(8) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.individualAllocId = one] : one \in Sample(4) }
        \cup { [ZeroSideAllocGrpComp2 EXCEPT !.tesEnrichmentRuleId = one] : one \in Sample(4) }
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
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp17,
      lastPx            : Sample(8),
      transBkdTime      : Sample(8),
      marketSegmentId   : Sample(4),
      packageId         : Sample(4),
      tesExecId         : Sample(4),
      settlDate         : Sample(4),
      trdType           : Sample(2),
      tradeReportType   : Sample(1),
      tradeReportText   : Sample(20),
      tradeReportId     : Sample(20),
      pad4              : Sample(4),
      sideAllocGrpComp  : SampleLists(OneSideAllocGrpComp2) ]

EncodeModifyTesTradeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp17(message.requestHeaderComp)
        \o message.lastPx
        \o message.transBkdTime
        \o message.marketSegmentId
        \o message.packageId
        \o message.tesExecId
        \o message.settlDate
        \o message.trdType
        \o message.tradeReportType
        \o EncodeUIntBE(Len(message.sideAllocGrpComp), 1)
        \o message.tradeReportText
        \o message.tradeReportId
        \o message.pad4
        \o EncodeSideAllocGrpComp2List(message.sideAllocGrpComp)

DecodeModifyTesTradeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp17(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET lastPx == ReadBytes(requestHeaderComp.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(lastPx.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(transBkdTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET packageId == ReadBytes(marketSegmentId.rest, 4) IN IF ~packageId.ok THEN Fail ELSE
    LET tesExecId == ReadBytes(packageId.rest, 4) IN IF ~tesExecId.ok THEN Fail ELSE
    LET settlDate == ReadBytes(tesExecId.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET trdType == ReadBytes(settlDate.rest, 2) IN IF ~trdType.ok THEN Fail ELSE
    LET tradeReportType == ReadBytes(trdType.rest, 1) IN IF ~tradeReportType.ok THEN Fail ELSE
    LET noSideAllocs == ReadUIntBE(tradeReportType.rest, 1) IN IF ~noSideAllocs.ok THEN Fail ELSE
    LET tradeReportText == ReadBytes(noSideAllocs.rest, 20) IN IF ~tradeReportText.ok THEN Fail ELSE
    LET tradeReportId == ReadBytes(tradeReportText.rest, 20) IN IF ~tradeReportId.ok THEN Fail ELSE
    LET pad4 == ReadBytes(tradeReportId.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    LET sideAllocGrpComp == ReadSideAllocGrpComp2List(pad4.rest, noSideAllocs.value) IN IF ~sideAllocGrpComp.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         lastPx            |-> lastPx.value,
         transBkdTime      |-> transBkdTime.value,
         marketSegmentId   |-> marketSegmentId.value,
         packageId         |-> packageId.value,
         tesExecId         |-> tesExecId.value,
         settlDate         |-> settlDate.value,
         trdType           |-> trdType.value,
         tradeReportType   |-> tradeReportType.value,
         tradeReportText   |-> tradeReportText.value,
         tradeReportId     |-> tradeReportId.value,
         pad4              |-> pad4.value,
         sideAllocGrpComp  |-> sideAllocGrpComp.value ], sideAllocGrpComp.rest)

ZeroModifyTesTradeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp17,
      lastPx            |-> [i \in 1 .. 8 |-> 0],
      transBkdTime      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      packageId         |-> [i \in 1 .. 4 |-> 0],
      tesExecId         |-> [i \in 1 .. 4 |-> 0],
      settlDate         |-> [i \in 1 .. 4 |-> 0],
      trdType           |-> [i \in 1 .. 2 |-> 0],
      tradeReportType   |-> [i \in 1 .. 1 |-> 0],
      tradeReportText   |-> [i \in 1 .. 20 |-> 0],
      tradeReportId     |-> [i \in 1 .. 20 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0],
      sideAllocGrpComp  |-> << >> ]

(* Modify Tes Trade Request at zero, then each field in turn at the values it is checked at *)
CheckedModifyTesTradeRequest ==
    { ZeroModifyTesTradeRequest }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp17 }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.packageId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tesExecId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.trdType = one] : one \in Sample(2) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradeReportType = one] : one \in Sample(1) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradeReportText = one] : one \in Sample(20) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.tradeReportId = one] : one \in Sample(20) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }
        \cup { [ZeroModifyTesTradeRequest EXCEPT !.sideAllocGrpComp = one] : one \in SampleLists(OneSideAllocGrpComp2) }

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
(* New Order Single Request: 242 bytes                                     *)
(***************************************************************************)

NewOrderSingleRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp18,
      price                                   : Sample(8),
      orderQty                                : Sample(8),
      displayQty                              : Sample(8),
      displayLowQty                           : Sample(8),
      displayHighQty                          : Sample(8),
      stopPx                                  : Sample(8),
      volumeDiscoveryPrice                    : Sample(8),
      pegOffsetValueAbs                       : Sample(8),
      pegOffsetValuePct                       : Sample(8),
      clOrdId                                 : Sample(8),
      securityId                              : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      quoteId                                 : Sample(8),
      expireDate                              : Sample(4),
      marketSegmentId                         : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      matchInstCrossId                        : Sample(4),
      applSeqIndicator                        : Sample(1),
      side                                    : Sample(1),
      ordType                                 : Sample(1),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      valueCheckTypeQuantity                  : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      timeInForce                             : Sample(1),
      execInst                                : Sample(1),
      tradingSessionSubId                     : Sample(1),
      tradeAtCloseOptIn                       : Sample(1),
      tradingCapacity                         : Sample(1),
      orderOrigination                        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText4                               : Sample(16),
      fixClOrdId                              : Sample(20),
      pad2v2                                  : Sample(2) ]

EncodeNewOrderSingleRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp18(message.requestHeaderComp)
        \o message.price
        \o message.orderQty
        \o message.displayQty
        \o message.displayLowQty
        \o message.displayHighQty
        \o message.stopPx
        \o message.volumeDiscoveryPrice
        \o message.pegOffsetValueAbs
        \o message.pegOffsetValuePct
        \o message.clOrdId
        \o message.securityId
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.quoteId
        \o message.expireDate
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.matchInstCrossId
        \o message.applSeqIndicator
        \o message.side
        \o message.ordType
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.valueCheckTypeQuantity
        \o message.orderAttributeLiquidityProvision
        \o message.timeInForce
        \o message.execInst
        \o message.tradingSessionSubId
        \o message.tradeAtCloseOptIn
        \o message.tradingCapacity
        \o message.orderOrigination
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.fixClOrdId
        \o message.pad2v2

DecodeNewOrderSingleRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp18(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET price == ReadBytes(requestHeaderComp.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(orderQty.rest, 8) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayLowQty == ReadBytes(displayQty.rest, 8) IN IF ~displayLowQty.ok THEN Fail ELSE
    LET displayHighQty == ReadBytes(displayLowQty.rest, 8) IN IF ~displayHighQty.ok THEN Fail ELSE
    LET stopPx == ReadBytes(displayHighQty.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET volumeDiscoveryPrice == ReadBytes(stopPx.rest, 8) IN IF ~volumeDiscoveryPrice.ok THEN Fail ELSE
    LET pegOffsetValueAbs == ReadBytes(volumeDiscoveryPrice.rest, 8) IN IF ~pegOffsetValueAbs.ok THEN Fail ELSE
    LET pegOffsetValuePct == ReadBytes(pegOffsetValueAbs.rest, 8) IN IF ~pegOffsetValuePct.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(pegOffsetValuePct.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET securityId == ReadBytes(clOrdId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(securityId.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET quoteId == ReadBytes(executingTrader.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET expireDate == ReadBytes(quoteId.rest, 4) IN IF ~expireDate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(expireDate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(targetPartyIdSessionId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(matchInstCrossId.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET side == ReadBytes(applSeqIndicator.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ordType == ReadBytes(side.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(ordType.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(execInst.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradeAtCloseOptIn == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradeAtCloseOptIn.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(tradeAtCloseOptIn.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(executingTraderQualifier.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyExecutingTrader.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET fixClOrdId == ReadBytes(freeText4.rest, 20) IN IF ~fixClOrdId.ok THEN Fail ELSE
    LET pad2v2 == ReadBytes(fixClOrdId.rest, 2) IN IF ~pad2v2.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         price                                   |-> price.value,
         orderQty                                |-> orderQty.value,
         displayQty                              |-> displayQty.value,
         displayLowQty                           |-> displayLowQty.value,
         displayHighQty                          |-> displayHighQty.value,
         stopPx                                  |-> stopPx.value,
         volumeDiscoveryPrice                    |-> volumeDiscoveryPrice.value,
         pegOffsetValueAbs                       |-> pegOffsetValueAbs.value,
         pegOffsetValuePct                       |-> pegOffsetValuePct.value,
         clOrdId                                 |-> clOrdId.value,
         securityId                              |-> securityId.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         quoteId                                 |-> quoteId.value,
         expireDate                              |-> expireDate.value,
         marketSegmentId                         |-> marketSegmentId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         applSeqIndicator                        |-> applSeqIndicator.value,
         side                                    |-> side.value,
         ordType                                 |-> ordType.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         valueCheckTypeQuantity                  |-> valueCheckTypeQuantity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         timeInForce                             |-> timeInForce.value,
         execInst                                |-> execInst.value,
         tradingSessionSubId                     |-> tradingSessionSubId.value,
         tradeAtCloseOptIn                       |-> tradeAtCloseOptIn.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText4                               |-> freeText4.value,
         fixClOrdId                              |-> fixClOrdId.value,
         pad2v2                                  |-> pad2v2.value ], pad2v2.rest)

ZeroNewOrderSingleRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp18,
      price                                   |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      displayQty                              |-> [i \in 1 .. 8 |-> 0],
      displayLowQty                           |-> [i \in 1 .. 8 |-> 0],
      displayHighQty                          |-> [i \in 1 .. 8 |-> 0],
      stopPx                                  |-> [i \in 1 .. 8 |-> 0],
      volumeDiscoveryPrice                    |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValueAbs                       |-> [i \in 1 .. 8 |-> 0],
      pegOffsetValuePct                       |-> [i \in 1 .. 8 |-> 0],
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      quoteId                                 |-> [i \in 1 .. 8 |-> 0],
      expireDate                              |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      applSeqIndicator                        |-> [i \in 1 .. 1 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      ordType                                 |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity                  |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      timeInForce                             |-> [i \in 1 .. 1 |-> 0],
      execInst                                |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId                     |-> [i \in 1 .. 1 |-> 0],
      tradeAtCloseOptIn                       |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText4                               |-> [i \in 1 .. 16 |-> 0],
      fixClOrdId                              |-> [i \in 1 .. 20 |-> 0],
      pad2v2                                  |-> [i \in 1 .. 2 |-> 0] ]

(* New Order Single Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleRequest ==
    { ZeroNewOrderSingleRequest }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp18 }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.displayQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.displayLowQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.displayHighQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.volumeDiscoveryPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.pegOffsetValueAbs = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.pegOffsetValuePct = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.expireDate = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.tradeAtCloseOptIn = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.fixClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderSingleRequest EXCEPT !.pad2v2 = one] : one \in Sample(2) }

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
(* New Order Single Short Request: 98 bytes                                *)
(***************************************************************************)

NewOrderSingleShortRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp19,
      securityId                              : Sample(8),
      price                                   : Sample(8),
      orderQty                                : Sample(8),
      clOrdId                                 : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      matchInstCrossId                        : Sample(4),
      enrichmentRuleId                        : Sample(2),
      side                                    : Sample(1),
      applSeqIndicator                        : Sample(1),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      valueCheckTypeQuantity                  : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      timeInForce                             : Sample(1),
      execInst                                : Sample(1),
      tradingCapacity                         : Sample(1),
      orderOrigination                        : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      pad6                                    : Sample(6) ]

EncodeNewOrderSingleShortRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp19(message.requestHeaderComp)
        \o message.securityId
        \o message.price
        \o message.orderQty
        \o message.clOrdId
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.matchInstCrossId
        \o message.enrichmentRuleId
        \o message.side
        \o message.applSeqIndicator
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.valueCheckTypeQuantity
        \o message.orderAttributeLiquidityProvision
        \o message.timeInForce
        \o message.execInst
        \o message.tradingCapacity
        \o message.orderOrigination
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.pad6

DecodeNewOrderSingleShortRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp19(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET price == ReadBytes(securityId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderQty.rest, 8) IN IF ~clOrdId.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(clOrdId.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(executingTrader.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET enrichmentRuleId == ReadBytes(matchInstCrossId.rest, 2) IN IF ~enrichmentRuleId.ok THEN Fail ELSE
    LET side == ReadBytes(enrichmentRuleId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET applSeqIndicator == ReadBytes(side.rest, 1) IN IF ~applSeqIndicator.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(applSeqIndicator.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET execInst == ReadBytes(timeInForce.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(execInst.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(orderOrigination.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET pad6 == ReadBytes(executingTraderQualifier.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         securityId                              |-> securityId.value,
         price                                   |-> price.value,
         orderQty                                |-> orderQty.value,
         clOrdId                                 |-> clOrdId.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         enrichmentRuleId                        |-> enrichmentRuleId.value,
         side                                    |-> side.value,
         applSeqIndicator                        |-> applSeqIndicator.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         valueCheckTypeQuantity                  |-> valueCheckTypeQuantity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         timeInForce                             |-> timeInForce.value,
         execInst                                |-> execInst.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderOrigination                        |-> orderOrigination.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         pad6                                    |-> pad6.value ], pad6.rest)

ZeroNewOrderSingleShortRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp19,
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      clOrdId                                 |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      enrichmentRuleId                        |-> [i \in 1 .. 2 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      applSeqIndicator                        |-> [i \in 1 .. 1 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity                  |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      timeInForce                             |-> [i \in 1 .. 1 |-> 0],
      execInst                                |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      pad6                                    |-> [i \in 1 .. 6 |-> 0] ]

(* New Order Single Short Request at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingleShortRequest ==
    { ZeroNewOrderSingleShortRequest }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp19 }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.clOrdId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.enrichmentRuleId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.applSeqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingleShortRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Ping Request: 26 bytes                                                  *)
(***************************************************************************)

PingRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp20,
      partitionId       : Sample(2),
      pad6              : Sample(6) ]

EncodePingRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp20(message.requestHeaderComp)
        \o message.partitionId
        \o message.pad6

DecodePingRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp20(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partitionId == ReadBytes(requestHeaderComp.rest, 2) IN IF ~partitionId.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partitionId.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         partitionId       |-> partitionId.value,
         pad6              |-> pad6.value ], pad6.rest)

ZeroPingRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp20,
      partitionId       |-> [i \in 1 .. 2 |-> 0],
      pad6              |-> [i \in 1 .. 6 |-> 0] ]

(* Ping Request at zero, then each field in turn at the values it is checked at *)
CheckedPingRequest ==
    { ZeroPingRequest }
        \cup { [ZeroPingRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroPingRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroPingRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp20 }
        \cup { [ZeroPingRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroPingRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Quote Activation Request: 50 bytes                                      *)
(***************************************************************************)

QuoteActivationRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp21,
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      targetPartyIdSessionId                  : Sample(4),
      massActionType                          : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      executingTraderQualifier                : Sample(1),
      pad5                                    : Sample(5) ]

EncodeQuoteActivationRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp21(message.requestHeaderComp)
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.targetPartyIdSessionId
        \o message.massActionType
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.executingTraderQualifier
        \o message.pad5

DecodeQuoteActivationRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp21(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(requestHeaderComp.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET targetPartyIdSessionId == ReadBytes(marketSegmentId.rest, 4) IN IF ~targetPartyIdSessionId.ok THEN Fail ELSE
    LET massActionType == ReadBytes(targetPartyIdSessionId.rest, 1) IN IF ~massActionType.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(massActionType.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET pad5 == ReadBytes(executingTraderQualifier.rest, 5) IN IF ~pad5.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         targetPartyIdSessionId                  |-> targetPartyIdSessionId.value,
         massActionType                          |-> massActionType.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         pad5                                    |-> pad5.value ], pad5.rest)

ZeroQuoteActivationRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp21,
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      targetPartyIdSessionId                  |-> [i \in 1 .. 4 |-> 0],
      massActionType                          |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      pad5                                    |-> [i \in 1 .. 5 |-> 0] ]

(* Quote Activation Request at zero, then each field in turn at the values it is checked at *)
CheckedQuoteActivationRequest ==
    { ZeroQuoteActivationRequest }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp21 }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.targetPartyIdSessionId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.massActionType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroQuoteActivationRequest EXCEPT !.pad5 = one] : one \in Sample(5) }

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
(* Rfq Request: 50 bytes                                                   *)
(***************************************************************************)

RfqRequest ==
    [ networkMsgId                      : Sample(8),
      pad2                              : Sample(2),
      requestHeaderComp                 : RequestHeaderComp22,
      securityId                        : Sample(8),
      orderQty                          : Sample(8),
      quoteId                           : Sample(8),
      marketSegmentId                   : Sample(4),
      rfqPublishIndicator               : Sample(1),
      rfqRequesterDisclosureInstruction : Sample(1),
      side                              : Sample(1),
      pad1                              : Sample(1) ]

EncodeRfqRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp22(message.requestHeaderComp)
        \o message.securityId
        \o message.orderQty
        \o message.quoteId
        \o message.marketSegmentId
        \o message.rfqPublishIndicator
        \o message.rfqRequesterDisclosureInstruction
        \o message.side
        \o message.pad1

DecodeRfqRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp22(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(securityId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET quoteId == ReadBytes(orderQty.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET rfqPublishIndicator == ReadBytes(marketSegmentId.rest, 1) IN IF ~rfqPublishIndicator.ok THEN Fail ELSE
    LET rfqRequesterDisclosureInstruction == ReadBytes(rfqPublishIndicator.rest, 1) IN IF ~rfqRequesterDisclosureInstruction.ok THEN Fail ELSE
    LET side == ReadBytes(rfqRequesterDisclosureInstruction.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET pad1 == ReadBytes(side.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    Ok([ networkMsgId                      |-> networkMsgId.value,
         pad2                              |-> pad2.value,
         requestHeaderComp                 |-> requestHeaderComp.value,
         securityId                        |-> securityId.value,
         orderQty                          |-> orderQty.value,
         quoteId                           |-> quoteId.value,
         marketSegmentId                   |-> marketSegmentId.value,
         rfqPublishIndicator               |-> rfqPublishIndicator.value,
         rfqRequesterDisclosureInstruction |-> rfqRequesterDisclosureInstruction.value,
         side                              |-> side.value,
         pad1                              |-> pad1.value ], pad1.rest)

ZeroRfqRequest ==
    [ networkMsgId                      |-> [i \in 1 .. 8 |-> 0],
      pad2                              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                 |-> ZeroRequestHeaderComp22,
      securityId                        |-> [i \in 1 .. 8 |-> 0],
      orderQty                          |-> [i \in 1 .. 8 |-> 0],
      quoteId                           |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                   |-> [i \in 1 .. 4 |-> 0],
      rfqPublishIndicator               |-> [i \in 1 .. 1 |-> 0],
      rfqRequesterDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      side                              |-> [i \in 1 .. 1 |-> 0],
      pad1                              |-> [i \in 1 .. 1 |-> 0] ]

(* Rfq Request at zero, then each field in turn at the values it is checked at *)
CheckedRfqRequest ==
    { ZeroRfqRequest }
        \cup { [ZeroRfqRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp22 }
        \cup { [ZeroRfqRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroRfqRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroRfqRequest EXCEPT !.rfqPublishIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRfqRequest EXCEPT !.rfqRequesterDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroRfqRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRfqRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

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
(* Retransmit Me Message Request: 58 bytes                                 *)
(***************************************************************************)

RetransmitMeMessageRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp23,
      subscriptionScope : Sample(4),
      partitionId       : Sample(2),
      refApplId         : Sample(1),
      applBegMsgId      : Sample(16),
      applEndMsgId      : Sample(16),
      pad1              : Sample(1) ]

EncodeRetransmitMeMessageRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp23(message.requestHeaderComp)
        \o message.subscriptionScope
        \o message.partitionId
        \o message.refApplId
        \o message.applBegMsgId
        \o message.applEndMsgId
        \o message.pad1

DecodeRetransmitMeMessageRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp23(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp23,
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
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp23 }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.subscriptionScope = one] : one \in Sample(4) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.applBegMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.applEndMsgId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmitMeMessageRequest EXCEPT !.pad1 = one] : one \in Sample(1) }

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
(* Retransmit Request: 42 bytes                                            *)
(***************************************************************************)

RetransmitRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp24,
      applBegSeqNum     : Sample(8),
      applEndSeqNum     : Sample(8),
      partitionId       : Sample(2),
      refApplId         : Sample(1),
      pad5              : Sample(5) ]

EncodeRetransmitRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp24(message.requestHeaderComp)
        \o message.applBegSeqNum
        \o message.applEndSeqNum
        \o message.partitionId
        \o message.refApplId
        \o message.pad5

DecodeRetransmitRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp24(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp24,
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
        \cup { [ZeroRetransmitRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp24 }
        \cup { [ZeroRetransmitRequest EXCEPT !.applBegSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.applEndSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.partitionId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmitRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroRetransmitRequest EXCEPT !.pad5 = one] : one \in Sample(5) }

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
(* Single Quote Request: 154 bytes                                         *)
(***************************************************************************)

SingleQuoteRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp25,
      quoteId                                 : Sample(8),
      securityId                              : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      bidPx                                   : Sample(8),
      bidSize                                 : Sample(8),
      offerPx                                 : Sample(8),
      offerSize                               : Sample(8),
      settlCurrFxRate                         : Sample(8),
      marketSegmentId                         : Sample(4),
      matchInstCrossId                        : Sample(4),
      priceValidityCheckType                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      valueCheckTypeQuantity                  : Sample(1),
      quoteSizeType                           : Sample(1),
      quoteType                               : Sample(1),
      tradingCapacity                         : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText4                               : Sample(16),
      pad7                                    : Sample(7) ]

EncodeSingleQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp25(message.requestHeaderComp)
        \o message.quoteId
        \o message.securityId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.bidPx
        \o message.bidSize
        \o message.offerPx
        \o message.offerSize
        \o message.settlCurrFxRate
        \o message.marketSegmentId
        \o message.matchInstCrossId
        \o message.priceValidityCheckType
        \o message.valueCheckTypeValue
        \o message.valueCheckTypeQuantity
        \o message.quoteSizeType
        \o message.quoteType
        \o message.tradingCapacity
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.pad7

DecodeSingleQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp25(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteId.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(securityId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET bidPx == ReadBytes(executingTrader.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidSize.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPx.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET settlCurrFxRate == ReadBytes(offerSize.rest, 8) IN IF ~settlCurrFxRate.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(settlCurrFxRate.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET matchInstCrossId == ReadBytes(marketSegmentId.rest, 4) IN IF ~matchInstCrossId.ok THEN Fail ELSE
    LET priceValidityCheckType == ReadBytes(matchInstCrossId.rest, 1) IN IF ~priceValidityCheckType.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(priceValidityCheckType.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET quoteSizeType == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~quoteSizeType.ok THEN Fail ELSE
    LET quoteType == ReadBytes(quoteSizeType.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(quoteType.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET pad7 == ReadBytes(freeText4.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         quoteId                                 |-> quoteId.value,
         securityId                              |-> securityId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         bidPx                                   |-> bidPx.value,
         bidSize                                 |-> bidSize.value,
         offerPx                                 |-> offerPx.value,
         offerSize                               |-> offerSize.value,
         settlCurrFxRate                         |-> settlCurrFxRate.value,
         marketSegmentId                         |-> marketSegmentId.value,
         matchInstCrossId                        |-> matchInstCrossId.value,
         priceValidityCheckType                  |-> priceValidityCheckType.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         valueCheckTypeQuantity                  |-> valueCheckTypeQuantity.value,
         quoteSizeType                           |-> quoteSizeType.value,
         quoteType                               |-> quoteType.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText4                               |-> freeText4.value,
         pad7                                    |-> pad7.value ], pad7.rest)

ZeroSingleQuoteRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp25,
      quoteId                                 |-> [i \in 1 .. 8 |-> 0],
      securityId                              |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      bidPx                                   |-> [i \in 1 .. 8 |-> 0],
      bidSize                                 |-> [i \in 1 .. 8 |-> 0],
      offerPx                                 |-> [i \in 1 .. 8 |-> 0],
      offerSize                               |-> [i \in 1 .. 8 |-> 0],
      settlCurrFxRate                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      matchInstCrossId                        |-> [i \in 1 .. 4 |-> 0],
      priceValidityCheckType                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity                  |-> [i \in 1 .. 1 |-> 0],
      quoteSizeType                           |-> [i \in 1 .. 1 |-> 0],
      quoteType                               |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText4                               |-> [i \in 1 .. 16 |-> 0],
      pad7                                    |-> [i \in 1 .. 7 |-> 0] ]

(* Single Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedSingleQuoteRequest ==
    { ZeroSingleQuoteRequest }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp25 }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.settlCurrFxRate = one] : one \in Sample(8) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.matchInstCrossId = one] : one \in Sample(4) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.priceValidityCheckType = one] : one \in Sample(1) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.quoteSizeType = one] : one \in Sample(1) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroSingleQuoteRequest EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Specialist Rfq Reject Request: 50 bytes                                 *)
(***************************************************************************)

SpecialistRfqRejectRequest ==
    [ networkMsgId             : Sample(8),
      pad2                     : Sample(2),
      requestHeaderComp        : RequestHeaderComp26,
      securityId               : Sample(8),
      quoteId                  : Sample(8),
      marketSegmentId          : Sample(4),
      quoteRequestRejectReason : Sample(1),
      partyExecutingFirm       : Sample(5),
      pad6                     : Sample(6) ]

EncodeSpecialistRfqRejectRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp26(message.requestHeaderComp)
        \o message.securityId
        \o message.quoteId
        \o message.marketSegmentId
        \o message.quoteRequestRejectReason
        \o message.partyExecutingFirm
        \o message.pad6

DecodeSpecialistRfqRejectRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp26(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(securityId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(quoteId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET quoteRequestRejectReason == ReadBytes(marketSegmentId.rest, 1) IN IF ~quoteRequestRejectReason.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(quoteRequestRejectReason.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET pad6 == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~pad6.ok THEN Fail ELSE
    Ok([ networkMsgId             |-> networkMsgId.value,
         pad2                     |-> pad2.value,
         requestHeaderComp        |-> requestHeaderComp.value,
         securityId               |-> securityId.value,
         quoteId                  |-> quoteId.value,
         marketSegmentId          |-> marketSegmentId.value,
         quoteRequestRejectReason |-> quoteRequestRejectReason.value,
         partyExecutingFirm       |-> partyExecutingFirm.value,
         pad6                     |-> pad6.value ], pad6.rest)

ZeroSpecialistRfqRejectRequest ==
    [ networkMsgId             |-> [i \in 1 .. 8 |-> 0],
      pad2                     |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp        |-> ZeroRequestHeaderComp26,
      securityId               |-> [i \in 1 .. 8 |-> 0],
      quoteId                  |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId          |-> [i \in 1 .. 4 |-> 0],
      quoteRequestRejectReason |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm       |-> [i \in 1 .. 5 |-> 0],
      pad6                     |-> [i \in 1 .. 6 |-> 0] ]

(* Specialist Rfq Reject Request at zero, then each field in turn at the values it is checked at *)
CheckedSpecialistRfqRejectRequest ==
    { ZeroSpecialistRfqRejectRequest }
        \cup { [ZeroSpecialistRfqRejectRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqRejectRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistRfqRejectRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp26 }
        \cup { [ZeroSpecialistRfqRejectRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqRejectRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqRejectRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistRfqRejectRequest EXCEPT !.quoteRequestRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistRfqRejectRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSpecialistRfqRejectRequest EXCEPT !.pad6 = one] : one \in Sample(6) }

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
(* Specialist Rfq Reply Request: 82 bytes                                  *)
(***************************************************************************)

SpecialistRfqReplyRequest ==
    [ networkMsgId       : Sample(8),
      pad2               : Sample(2),
      requestHeaderComp  : RequestHeaderComp27,
      securityId         : Sample(8),
      quoteId            : Sample(8),
      bidPx              : Sample(8),
      bidSize            : Sample(8),
      offerPx            : Sample(8),
      offerSize          : Sample(8),
      marketSegmentId    : Sample(4),
      partyExecutingFirm : Sample(5),
      pad7               : Sample(7) ]

EncodeSpecialistRfqReplyRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp27(message.requestHeaderComp)
        \o message.securityId
        \o message.quoteId
        \o message.bidPx
        \o message.bidSize
        \o message.offerPx
        \o message.offerSize
        \o message.marketSegmentId
        \o message.partyExecutingFirm
        \o message.pad7

DecodeSpecialistRfqReplyRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp27(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(securityId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(quoteId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidSize.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPx.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(offerSize.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(marketSegmentId.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET pad7 == ReadBytes(partyExecutingFirm.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ networkMsgId       |-> networkMsgId.value,
         pad2               |-> pad2.value,
         requestHeaderComp  |-> requestHeaderComp.value,
         securityId         |-> securityId.value,
         quoteId            |-> quoteId.value,
         bidPx              |-> bidPx.value,
         bidSize            |-> bidSize.value,
         offerPx            |-> offerPx.value,
         offerSize          |-> offerSize.value,
         marketSegmentId    |-> marketSegmentId.value,
         partyExecutingFirm |-> partyExecutingFirm.value,
         pad7               |-> pad7.value ], pad7.rest)

ZeroSpecialistRfqReplyRequest ==
    [ networkMsgId       |-> [i \in 1 .. 8 |-> 0],
      pad2               |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp  |-> ZeroRequestHeaderComp27,
      securityId         |-> [i \in 1 .. 8 |-> 0],
      quoteId            |-> [i \in 1 .. 8 |-> 0],
      bidPx              |-> [i \in 1 .. 8 |-> 0],
      bidSize            |-> [i \in 1 .. 8 |-> 0],
      offerPx            |-> [i \in 1 .. 8 |-> 0],
      offerSize          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId    |-> [i \in 1 .. 4 |-> 0],
      partyExecutingFirm |-> [i \in 1 .. 5 |-> 0],
      pad7               |-> [i \in 1 .. 7 |-> 0] ]

(* Specialist Rfq Reply Request at zero, then each field in turn at the values it is checked at *)
CheckedSpecialistRfqReplyRequest ==
    { ZeroSpecialistRfqReplyRequest }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp27 }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroSpecialistRfqReplyRequest EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Specialist Security State Change Request: 34 bytes                      *)
(***************************************************************************)

SpecialistSecurityStateChangeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp28,
      securityId        : Sample(8),
      marketSegmentId   : Sample(4),
      eventType         : Sample(1),
      pad3              : Sample(3) ]

EncodeSpecialistSecurityStateChangeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp28(message.requestHeaderComp)
        \o message.securityId
        \o message.marketSegmentId
        \o message.eventType
        \o message.pad3

DecodeSpecialistSecurityStateChangeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp28(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(securityId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET eventType == ReadBytes(marketSegmentId.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET pad3 == ReadBytes(eventType.rest, 3) IN IF ~pad3.ok THEN Fail ELSE
    Ok([ networkMsgId      |-> networkMsgId.value,
         pad2              |-> pad2.value,
         requestHeaderComp |-> requestHeaderComp.value,
         securityId        |-> securityId.value,
         marketSegmentId   |-> marketSegmentId.value,
         eventType         |-> eventType.value,
         pad3              |-> pad3.value ], pad3.rest)

ZeroSpecialistSecurityStateChangeRequest ==
    [ networkMsgId      |-> [i \in 1 .. 8 |-> 0],
      pad2              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp |-> ZeroRequestHeaderComp28,
      securityId        |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId   |-> [i \in 1 .. 4 |-> 0],
      eventType         |-> [i \in 1 .. 1 |-> 0],
      pad3              |-> [i \in 1 .. 3 |-> 0] ]

(* Specialist Security State Change Request at zero, then each field in turn at the values it is checked at *)
CheckedSpecialistSecurityStateChangeRequest ==
    { ZeroSpecialistSecurityStateChangeRequest }
        \cup { [ZeroSpecialistSecurityStateChangeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistSecurityStateChangeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialistSecurityStateChangeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp28 }
        \cup { [ZeroSpecialistSecurityStateChangeRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroSpecialistSecurityStateChangeRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSpecialistSecurityStateChangeRequest EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroSpecialistSecurityStateChangeRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

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
(* Subscribe Request: 26 bytes                                             *)
(***************************************************************************)

SubscribeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp29,
      subscriptionScope : Sample(4),
      refApplId         : Sample(1),
      pad3              : Sample(3) ]

EncodeSubscribeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp29(message.requestHeaderComp)
        \o message.subscriptionScope
        \o message.refApplId
        \o message.pad3

DecodeSubscribeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp29(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp29,
      subscriptionScope |-> [i \in 1 .. 4 |-> 0],
      refApplId         |-> [i \in 1 .. 1 |-> 0],
      pad3              |-> [i \in 1 .. 3 |-> 0] ]

(* Subscribe Request at zero, then each field in turn at the values it is checked at *)
CheckedSubscribeRequest ==
    { ZeroSubscribeRequest }
        \cup { [ZeroSubscribeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroSubscribeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroSubscribeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp29 }
        \cup { [ZeroSubscribeRequest EXCEPT !.subscriptionScope = one] : one \in Sample(4) }
        \cup { [ZeroSubscribeRequest EXCEPT !.refApplId = one] : one \in Sample(1) }
        \cup { [ZeroSubscribeRequest EXCEPT !.pad3 = one] : one \in Sample(3) }

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
(* Unsubscribe Request: 26 bytes                                           *)
(***************************************************************************)

UnsubscribeRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp30,
      refApplSubId      : Sample(4),
      pad4              : Sample(4) ]

EncodeUnsubscribeRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp30(message.requestHeaderComp)
        \o message.refApplSubId
        \o message.pad4

DecodeUnsubscribeRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp30(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp30,
      refApplSubId      |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* Unsubscribe Request at zero, then each field in turn at the values it is checked at *)
CheckedUnsubscribeRequest ==
    { ZeroUnsubscribeRequest }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp30 }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.refApplSubId = one] : one \in Sample(4) }
        \cup { [ZeroUnsubscribeRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

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
(* User Login Request: 58 bytes                                            *)
(***************************************************************************)

UserLoginRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp31,
      username          : Sample(4),
      password          : Sample(32),
      pad4              : Sample(4) ]

EncodeUserLoginRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp31(message.requestHeaderComp)
        \o message.username
        \o message.password
        \o message.pad4

DecodeUserLoginRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp31(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp31,
      username          |-> [i \in 1 .. 4 |-> 0],
      password          |-> [i \in 1 .. 32 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* User Login Request at zero, then each field in turn at the values it is checked at *)
CheckedUserLoginRequest ==
    { ZeroUserLoginRequest }
        \cup { [ZeroUserLoginRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserLoginRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLoginRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp31 }
        \cup { [ZeroUserLoginRequest EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserLoginRequest EXCEPT !.password = one] : one \in Sample(32) }
        \cup { [ZeroUserLoginRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

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
(* User Logout Request: 26 bytes                                           *)
(***************************************************************************)

UserLogoutRequest ==
    [ networkMsgId      : Sample(8),
      pad2              : Sample(2),
      requestHeaderComp : RequestHeaderComp32,
      username          : Sample(4),
      pad4              : Sample(4) ]

EncodeUserLogoutRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp32(message.requestHeaderComp)
        \o message.username
        \o message.pad4

DecodeUserLogoutRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp32(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
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
      requestHeaderComp |-> ZeroRequestHeaderComp32,
      username          |-> [i \in 1 .. 4 |-> 0],
      pad4              |-> [i \in 1 .. 4 |-> 0] ]

(* User Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedUserLogoutRequest ==
    { ZeroUserLogoutRequest }
        \cup { [ZeroUserLogoutRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp32 }
        \cup { [ZeroUserLogoutRequest EXCEPT !.username = one] : one \in Sample(4) }
        \cup { [ZeroUserLogoutRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

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
(* Xetra En Light Enter Quote Request: 146 bytes                           *)
(***************************************************************************)

XetraEnLightEnterQuoteRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp33,
      bidPx                                   : Sample(8),
      offerPx                                 : Sample(8),
      bidSize                                 : Sample(8),
      offerSize                               : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      negotiationId                           : Sample(4),
      valueCheckTypeQuantity                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      tradingCapacity                         : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      executingTraderQualifier                : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText4                               : Sample(16),
      pad7                                    : Sample(7) ]

EncodeXetraEnLightEnterQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp33(message.requestHeaderComp)
        \o message.bidPx
        \o message.offerPx
        \o message.bidSize
        \o message.offerSize
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.negotiationId
        \o message.valueCheckTypeQuantity
        \o message.valueCheckTypeValue
        \o message.tradingCapacity
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4
        \o message.pad7

DecodeXetraEnLightEnterQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp33(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET bidPx == ReadBytes(requestHeaderComp.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET bidSize == ReadBytes(offerPx.rest, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(offerSize.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(marketSegmentId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(negotiationId.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(partyExecutingTrader.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    LET pad7 == ReadBytes(freeText4.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         bidPx                                   |-> bidPx.value,
         offerPx                                 |-> offerPx.value,
         bidSize                                 |-> bidSize.value,
         offerSize                               |-> offerSize.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         negotiationId                           |-> negotiationId.value,
         valueCheckTypeQuantity                  |-> valueCheckTypeQuantity.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText4                               |-> freeText4.value,
         pad7                                    |-> pad7.value ], pad7.rest)

ZeroXetraEnLightEnterQuoteRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp33,
      bidPx                                   |-> [i \in 1 .. 8 |-> 0],
      offerPx                                 |-> [i \in 1 .. 8 |-> 0],
      bidSize                                 |-> [i \in 1 .. 8 |-> 0],
      offerSize                               |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      negotiationId                           |-> [i \in 1 .. 4 |-> 0],
      valueCheckTypeQuantity                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText4                               |-> [i \in 1 .. 16 |-> 0],
      pad7                                    |-> [i \in 1 .. 7 |-> 0] ]

(* Xetra En Light Enter Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightEnterQuoteRequest ==
    { ZeroXetraEnLightEnterQuoteRequest }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp33 }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.freeText4 = one] : one \in Sample(16) }
        \cup { [ZeroXetraEnLightEnterQuoteRequest EXCEPT !.pad7 = one] : one \in Sample(7) }

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
(* Xetra En Light Hit Quote Request: 154 bytes                             *)
(***************************************************************************)

XetraEnLightHitQuoteRequest ==
    [ networkMsgId                            : Sample(8),
      pad2                                    : Sample(2),
      requestHeaderComp                       : RequestHeaderComp34,
      quoteId                                 : Sample(8),
      orderQty                                : Sample(8),
      price                                   : Sample(8),
      partyIdClientId                         : Sample(8),
      partyIdInvestmentDecisionMaker          : Sample(8),
      executingTrader                         : Sample(8),
      marketSegmentId                         : Sample(4),
      negotiationId                           : Sample(4),
      side                                    : Sample(1),
      valueCheckTypeQuantity                  : Sample(1),
      valueCheckTypeValue                     : Sample(1),
      tradingCapacity                         : Sample(1),
      orderAttributeLiquidityProvision        : Sample(1),
      executingTraderQualifier                : Sample(1),
      allocMethod                             : Sample(1),
      partyIdInvestmentDecisionMakerQualifier : Sample(1),
      orderOrigination                        : Sample(1),
      partyExecutingFirm                      : Sample(5),
      partyExecutingTrader                    : Sample(6),
      firmTradeId                             : Sample(20),
      freeText1                               : Sample(12),
      freeText2                               : Sample(12),
      freeText4                               : Sample(16) ]

EncodeXetraEnLightHitQuoteRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp34(message.requestHeaderComp)
        \o message.quoteId
        \o message.orderQty
        \o message.price
        \o message.partyIdClientId
        \o message.partyIdInvestmentDecisionMaker
        \o message.executingTrader
        \o message.marketSegmentId
        \o message.negotiationId
        \o message.side
        \o message.valueCheckTypeQuantity
        \o message.valueCheckTypeValue
        \o message.tradingCapacity
        \o message.orderAttributeLiquidityProvision
        \o message.executingTraderQualifier
        \o message.allocMethod
        \o message.partyIdInvestmentDecisionMakerQualifier
        \o message.orderOrigination
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.firmTradeId
        \o message.freeText1
        \o message.freeText2
        \o message.freeText4

DecodeXetraEnLightHitQuoteRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp34(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET quoteId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(quoteId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET partyIdClientId == ReadBytes(price.rest, 8) IN IF ~partyIdClientId.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMaker == ReadBytes(partyIdClientId.rest, 8) IN IF ~partyIdInvestmentDecisionMaker.ok THEN Fail ELSE
    LET executingTrader == ReadBytes(partyIdInvestmentDecisionMaker.rest, 8) IN IF ~executingTrader.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(executingTrader.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(marketSegmentId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET side == ReadBytes(negotiationId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(side.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET orderAttributeLiquidityProvision == ReadBytes(tradingCapacity.rest, 1) IN IF ~orderAttributeLiquidityProvision.ok THEN Fail ELSE
    LET executingTraderQualifier == ReadBytes(orderAttributeLiquidityProvision.rest, 1) IN IF ~executingTraderQualifier.ok THEN Fail ELSE
    LET allocMethod == ReadBytes(executingTraderQualifier.rest, 1) IN IF ~allocMethod.ok THEN Fail ELSE
    LET partyIdInvestmentDecisionMakerQualifier == ReadBytes(allocMethod.rest, 1) IN IF ~partyIdInvestmentDecisionMakerQualifier.ok THEN Fail ELSE
    LET orderOrigination == ReadBytes(partyIdInvestmentDecisionMakerQualifier.rest, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(orderOrigination.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET firmTradeId == ReadBytes(partyExecutingTrader.rest, 20) IN IF ~firmTradeId.ok THEN Fail ELSE
    LET freeText1 == ReadBytes(firmTradeId.rest, 12) IN IF ~freeText1.ok THEN Fail ELSE
    LET freeText2 == ReadBytes(freeText1.rest, 12) IN IF ~freeText2.ok THEN Fail ELSE
    LET freeText4 == ReadBytes(freeText2.rest, 16) IN IF ~freeText4.ok THEN Fail ELSE
    Ok([ networkMsgId                            |-> networkMsgId.value,
         pad2                                    |-> pad2.value,
         requestHeaderComp                       |-> requestHeaderComp.value,
         quoteId                                 |-> quoteId.value,
         orderQty                                |-> orderQty.value,
         price                                   |-> price.value,
         partyIdClientId                         |-> partyIdClientId.value,
         partyIdInvestmentDecisionMaker          |-> partyIdInvestmentDecisionMaker.value,
         executingTrader                         |-> executingTrader.value,
         marketSegmentId                         |-> marketSegmentId.value,
         negotiationId                           |-> negotiationId.value,
         side                                    |-> side.value,
         valueCheckTypeQuantity                  |-> valueCheckTypeQuantity.value,
         valueCheckTypeValue                     |-> valueCheckTypeValue.value,
         tradingCapacity                         |-> tradingCapacity.value,
         orderAttributeLiquidityProvision        |-> orderAttributeLiquidityProvision.value,
         executingTraderQualifier                |-> executingTraderQualifier.value,
         allocMethod                             |-> allocMethod.value,
         partyIdInvestmentDecisionMakerQualifier |-> partyIdInvestmentDecisionMakerQualifier.value,
         orderOrigination                        |-> orderOrigination.value,
         partyExecutingFirm                      |-> partyExecutingFirm.value,
         partyExecutingTrader                    |-> partyExecutingTrader.value,
         firmTradeId                             |-> firmTradeId.value,
         freeText1                               |-> freeText1.value,
         freeText2                               |-> freeText2.value,
         freeText4                               |-> freeText4.value ], freeText4.rest)

ZeroXetraEnLightHitQuoteRequest ==
    [ networkMsgId                            |-> [i \in 1 .. 8 |-> 0],
      pad2                                    |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                       |-> ZeroRequestHeaderComp34,
      quoteId                                 |-> [i \in 1 .. 8 |-> 0],
      orderQty                                |-> [i \in 1 .. 8 |-> 0],
      price                                   |-> [i \in 1 .. 8 |-> 0],
      partyIdClientId                         |-> [i \in 1 .. 8 |-> 0],
      partyIdInvestmentDecisionMaker          |-> [i \in 1 .. 8 |-> 0],
      executingTrader                         |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      negotiationId                           |-> [i \in 1 .. 4 |-> 0],
      side                                    |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity                  |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue                     |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                         |-> [i \in 1 .. 1 |-> 0],
      orderAttributeLiquidityProvision        |-> [i \in 1 .. 1 |-> 0],
      executingTraderQualifier                |-> [i \in 1 .. 1 |-> 0],
      allocMethod                             |-> [i \in 1 .. 1 |-> 0],
      partyIdInvestmentDecisionMakerQualifier |-> [i \in 1 .. 1 |-> 0],
      orderOrigination                        |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                      |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader                    |-> [i \in 1 .. 6 |-> 0],
      firmTradeId                             |-> [i \in 1 .. 20 |-> 0],
      freeText1                               |-> [i \in 1 .. 12 |-> 0],
      freeText2                               |-> [i \in 1 .. 12 |-> 0],
      freeText4                               |-> [i \in 1 .. 16 |-> 0] ]

(* Xetra En Light Hit Quote Request at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightHitQuoteRequest ==
    { ZeroXetraEnLightHitQuoteRequest }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp34 }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.partyIdClientId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.partyIdInvestmentDecisionMaker = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.executingTrader = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.orderAttributeLiquidityProvision = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.executingTraderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.allocMethod = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.partyIdInvestmentDecisionMakerQualifier = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.orderOrigination = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.firmTradeId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.freeText1 = one] : one \in Sample(12) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.freeText2 = one] : one \in Sample(12) }
        \cup { [ZeroXetraEnLightHitQuoteRequest EXCEPT !.freeText4 = one] : one \in Sample(16) }

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
(* Xetra En Light Open Negotiation Request                                 *)
(***************************************************************************)

XetraEnLightOpenNegotiationRequest ==
    [ networkMsgId                      : Sample(8),
      pad2                              : Sample(2),
      requestHeaderComp                 : RequestHeaderComp35,
      securityId                        : Sample(8),
      bidPx                             : Sample(8),
      offerPx                           : Sample(8),
      orderQty                          : Sample(8),
      validUntilTime                    : Sample(8),
      marketSegmentId                   : Sample(4),
      settlDate                         : Sample(4),
      numberOfRespDisclosureInstruction : Sample(1),
      side                              : Sample(1),
      valueCheckTypeValue               : Sample(1),
      valueCheckTypeQuantity            : Sample(1),
      respondentType                    : Sample(1),
      partyExecutingFirm                : Sample(5),
      partyExecutingTrader              : Sample(6),
      freeText5                         : Sample(132),
      quoteReqId                        : Sample(20),
      pad7                              : Sample(7),
      xetraEnLightTargetPartiesComp     : SampleLists(OneXetraEnLightTargetPartiesComp) ]

EncodeXetraEnLightOpenNegotiationRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp35(message.requestHeaderComp)
        \o message.securityId
        \o message.bidPx
        \o message.offerPx
        \o message.orderQty
        \o message.validUntilTime
        \o message.marketSegmentId
        \o message.settlDate
        \o EncodeUIntBE(Len(message.xetraEnLightTargetPartiesComp), 1)
        \o message.numberOfRespDisclosureInstruction
        \o message.side
        \o message.valueCheckTypeValue
        \o message.valueCheckTypeQuantity
        \o message.respondentType
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText5
        \o message.quoteReqId
        \o message.pad7
        \o EncodeXetraEnLightTargetPartiesCompList(message.xetraEnLightTargetPartiesComp)

DecodeXetraEnLightOpenNegotiationRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp35(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET securityId == ReadBytes(requestHeaderComp.rest, 8) IN IF ~securityId.ok THEN Fail ELSE
    LET bidPx == ReadBytes(securityId.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET orderQty == ReadBytes(offerPx.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET validUntilTime == ReadBytes(orderQty.rest, 8) IN IF ~validUntilTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(validUntilTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET settlDate == ReadBytes(marketSegmentId.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET noTargetPartyIDs == ReadUIntBE(settlDate.rest, 1) IN IF ~noTargetPartyIDs.ok THEN Fail ELSE
    LET numberOfRespDisclosureInstruction == ReadBytes(noTargetPartyIDs.rest, 1) IN IF ~numberOfRespDisclosureInstruction.ok THEN Fail ELSE
    LET side == ReadBytes(numberOfRespDisclosureInstruction.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET valueCheckTypeValue == ReadBytes(side.rest, 1) IN IF ~valueCheckTypeValue.ok THEN Fail ELSE
    LET valueCheckTypeQuantity == ReadBytes(valueCheckTypeValue.rest, 1) IN IF ~valueCheckTypeQuantity.ok THEN Fail ELSE
    LET respondentType == ReadBytes(valueCheckTypeQuantity.rest, 1) IN IF ~respondentType.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(respondentType.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(partyExecutingTrader.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(freeText5.rest, 20) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET pad7 == ReadBytes(quoteReqId.rest, 7) IN IF ~pad7.ok THEN Fail ELSE
    LET xetraEnLightTargetPartiesComp == ReadXetraEnLightTargetPartiesCompList(pad7.rest, noTargetPartyIDs.value) IN IF ~xetraEnLightTargetPartiesComp.ok THEN Fail ELSE
    Ok([ networkMsgId                      |-> networkMsgId.value,
         pad2                              |-> pad2.value,
         requestHeaderComp                 |-> requestHeaderComp.value,
         securityId                        |-> securityId.value,
         bidPx                             |-> bidPx.value,
         offerPx                           |-> offerPx.value,
         orderQty                          |-> orderQty.value,
         validUntilTime                    |-> validUntilTime.value,
         marketSegmentId                   |-> marketSegmentId.value,
         settlDate                         |-> settlDate.value,
         numberOfRespDisclosureInstruction |-> numberOfRespDisclosureInstruction.value,
         side                              |-> side.value,
         valueCheckTypeValue               |-> valueCheckTypeValue.value,
         valueCheckTypeQuantity            |-> valueCheckTypeQuantity.value,
         respondentType                    |-> respondentType.value,
         partyExecutingFirm                |-> partyExecutingFirm.value,
         partyExecutingTrader              |-> partyExecutingTrader.value,
         freeText5                         |-> freeText5.value,
         quoteReqId                        |-> quoteReqId.value,
         pad7                              |-> pad7.value,
         xetraEnLightTargetPartiesComp     |-> xetraEnLightTargetPartiesComp.value ], xetraEnLightTargetPartiesComp.rest)

ZeroXetraEnLightOpenNegotiationRequest ==
    [ networkMsgId                      |-> [i \in 1 .. 8 |-> 0],
      pad2                              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                 |-> ZeroRequestHeaderComp35,
      securityId                        |-> [i \in 1 .. 8 |-> 0],
      bidPx                             |-> [i \in 1 .. 8 |-> 0],
      offerPx                           |-> [i \in 1 .. 8 |-> 0],
      orderQty                          |-> [i \in 1 .. 8 |-> 0],
      validUntilTime                    |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                   |-> [i \in 1 .. 4 |-> 0],
      settlDate                         |-> [i \in 1 .. 4 |-> 0],
      numberOfRespDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      side                              |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeValue               |-> [i \in 1 .. 1 |-> 0],
      valueCheckTypeQuantity            |-> [i \in 1 .. 1 |-> 0],
      respondentType                    |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader              |-> [i \in 1 .. 6 |-> 0],
      freeText5                         |-> [i \in 1 .. 132 |-> 0],
      quoteReqId                        |-> [i \in 1 .. 20 |-> 0],
      pad7                              |-> [i \in 1 .. 7 |-> 0],
      xetraEnLightTargetPartiesComp     |-> << >> ]

(* Xetra En Light Open Negotiation Request at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightOpenNegotiationRequest ==
    { ZeroXetraEnLightOpenNegotiationRequest }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp35 }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.securityId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.validUntilTime = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.numberOfRespDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.valueCheckTypeValue = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.valueCheckTypeQuantity = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.respondentType = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.quoteReqId = one] : one \in Sample(20) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.pad7 = one] : one \in Sample(7) }
        \cup { [ZeroXetraEnLightOpenNegotiationRequest EXCEPT !.xetraEnLightTargetPartiesComp = one] : one \in SampleLists(OneXetraEnLightTargetPartiesComp) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp36 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp36(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp36(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp36 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp36 ==
    { ZeroRequestHeaderComp36 }
        \cup { [ZeroRequestHeaderComp36 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp36 EXCEPT !.senderSubId = one] : one \in Sample(4) }

(***************************************************************************)
(* Xetra En Light Quoting Status Request: 42 bytes                         *)
(***************************************************************************)

XetraEnLightQuotingStatusRequest ==
    [ networkMsgId         : Sample(8),
      pad2                 : Sample(2),
      requestHeaderComp    : RequestHeaderComp36,
      marketSegmentId      : Sample(4),
      negotiationId        : Sample(4),
      quotingStatus        : Sample(1),
      partyExecutingFirm   : Sample(5),
      partyExecutingTrader : Sample(6),
      pad4                 : Sample(4) ]

EncodeXetraEnLightQuotingStatusRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp36(message.requestHeaderComp)
        \o message.marketSegmentId
        \o message.negotiationId
        \o message.quotingStatus
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.pad4

DecodeXetraEnLightQuotingStatusRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp36(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(requestHeaderComp.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(marketSegmentId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET quotingStatus == ReadBytes(negotiationId.rest, 1) IN IF ~quotingStatus.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(quotingStatus.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET pad4 == ReadBytes(partyExecutingTrader.rest, 4) IN IF ~pad4.ok THEN Fail ELSE
    Ok([ networkMsgId         |-> networkMsgId.value,
         pad2                 |-> pad2.value,
         requestHeaderComp    |-> requestHeaderComp.value,
         marketSegmentId      |-> marketSegmentId.value,
         negotiationId        |-> negotiationId.value,
         quotingStatus        |-> quotingStatus.value,
         partyExecutingFirm   |-> partyExecutingFirm.value,
         partyExecutingTrader |-> partyExecutingTrader.value,
         pad4                 |-> pad4.value ], pad4.rest)

ZeroXetraEnLightQuotingStatusRequest ==
    [ networkMsgId         |-> [i \in 1 .. 8 |-> 0],
      pad2                 |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp    |-> ZeroRequestHeaderComp36,
      marketSegmentId      |-> [i \in 1 .. 4 |-> 0],
      negotiationId        |-> [i \in 1 .. 4 |-> 0],
      quotingStatus        |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm   |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader |-> [i \in 1 .. 6 |-> 0],
      pad4                 |-> [i \in 1 .. 4 |-> 0] ]

(* Xetra En Light Quoting Status Request at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightQuotingStatusRequest ==
    { ZeroXetraEnLightQuotingStatusRequest }
        \cup { [ZeroXetraEnLightQuotingStatusRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightQuotingStatusRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightQuotingStatusRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp36 }
        \cup { [ZeroXetraEnLightQuotingStatusRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightQuotingStatusRequest EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightQuotingStatusRequest EXCEPT !.quotingStatus = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightQuotingStatusRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightQuotingStatusRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightQuotingStatusRequest EXCEPT !.pad4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Request Header Comp: 8 bytes                                            *)
(***************************************************************************)

RequestHeaderComp37 ==
    [ msgSeqNum   : Sample(4),
      senderSubId : Sample(4) ]

EncodeRequestHeaderComp37(message) ==
    message.msgSeqNum
        \o message.senderSubId

DecodeRequestHeaderComp37(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET senderSubId == ReadBytes(msgSeqNum.rest, 4) IN IF ~senderSubId.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         senderSubId |-> senderSubId.value ], senderSubId.rest)

ZeroRequestHeaderComp37 ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      senderSubId |-> [i \in 1 .. 4 |-> 0] ]

(* Request Header Comp at zero, then each field in turn at the values it is checked at *)
CheckedRequestHeaderComp37 ==
    { ZeroRequestHeaderComp37 }
        \cup { [ZeroRequestHeaderComp37 EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestHeaderComp37 EXCEPT !.senderSubId = one] : one \in Sample(4) }

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
(* Xetra En Light Update Negotiation Request                               *)
(***************************************************************************)

XetraEnLightUpdateNegotiationRequest ==
    [ networkMsgId                      : Sample(8),
      pad2                              : Sample(2),
      requestHeaderComp                 : RequestHeaderComp37,
      bidPx                             : Sample(8),
      offerPx                           : Sample(8),
      orderQty                          : Sample(8),
      marketSegmentId                   : Sample(4),
      negotiationId                     : Sample(4),
      settlDate                         : Sample(4),
      numberOfRespDisclosureInstruction : Sample(1),
      side                              : Sample(1),
      quoteCancelType                   : Sample(1),
      partyExecutingFirm                : Sample(5),
      partyExecutingTrader              : Sample(6),
      freeText5                         : Sample(132),
      pad1                              : Sample(1),
      xetraEnLightTargetPartiesComp     : SampleLists(OneXetraEnLightTargetPartiesComp2) ]

EncodeXetraEnLightUpdateNegotiationRequest(message) ==
    message.networkMsgId
        \o message.pad2
        \o EncodeRequestHeaderComp37(message.requestHeaderComp)
        \o message.bidPx
        \o message.offerPx
        \o message.orderQty
        \o message.marketSegmentId
        \o message.negotiationId
        \o message.settlDate
        \o EncodeUIntBE(Len(message.xetraEnLightTargetPartiesComp), 1)
        \o message.numberOfRespDisclosureInstruction
        \o message.side
        \o message.quoteCancelType
        \o message.partyExecutingFirm
        \o message.partyExecutingTrader
        \o message.freeText5
        \o message.pad1
        \o EncodeXetraEnLightTargetPartiesComp2List(message.xetraEnLightTargetPartiesComp)

DecodeXetraEnLightUpdateNegotiationRequest(bytes) ==
    LET networkMsgId == ReadBytes(bytes, 8) IN IF ~networkMsgId.ok THEN Fail ELSE
    LET pad2 == ReadBytes(networkMsgId.rest, 2) IN IF ~pad2.ok THEN Fail ELSE
    LET requestHeaderComp == DecodeRequestHeaderComp37(pad2.rest) IN IF ~requestHeaderComp.ok THEN Fail ELSE
    LET bidPx == ReadBytes(requestHeaderComp.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET orderQty == ReadBytes(offerPx.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(orderQty.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET negotiationId == ReadBytes(marketSegmentId.rest, 4) IN IF ~negotiationId.ok THEN Fail ELSE
    LET settlDate == ReadBytes(negotiationId.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET noTargetPartyIDs == ReadUIntBE(settlDate.rest, 1) IN IF ~noTargetPartyIDs.ok THEN Fail ELSE
    LET numberOfRespDisclosureInstruction == ReadBytes(noTargetPartyIDs.rest, 1) IN IF ~numberOfRespDisclosureInstruction.ok THEN Fail ELSE
    LET side == ReadBytes(numberOfRespDisclosureInstruction.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quoteCancelType == ReadBytes(side.rest, 1) IN IF ~quoteCancelType.ok THEN Fail ELSE
    LET partyExecutingFirm == ReadBytes(quoteCancelType.rest, 5) IN IF ~partyExecutingFirm.ok THEN Fail ELSE
    LET partyExecutingTrader == ReadBytes(partyExecutingFirm.rest, 6) IN IF ~partyExecutingTrader.ok THEN Fail ELSE
    LET freeText5 == ReadBytes(partyExecutingTrader.rest, 132) IN IF ~freeText5.ok THEN Fail ELSE
    LET pad1 == ReadBytes(freeText5.rest, 1) IN IF ~pad1.ok THEN Fail ELSE
    LET xetraEnLightTargetPartiesComp == ReadXetraEnLightTargetPartiesComp2List(pad1.rest, noTargetPartyIDs.value) IN IF ~xetraEnLightTargetPartiesComp.ok THEN Fail ELSE
    Ok([ networkMsgId                      |-> networkMsgId.value,
         pad2                              |-> pad2.value,
         requestHeaderComp                 |-> requestHeaderComp.value,
         bidPx                             |-> bidPx.value,
         offerPx                           |-> offerPx.value,
         orderQty                          |-> orderQty.value,
         marketSegmentId                   |-> marketSegmentId.value,
         negotiationId                     |-> negotiationId.value,
         settlDate                         |-> settlDate.value,
         numberOfRespDisclosureInstruction |-> numberOfRespDisclosureInstruction.value,
         side                              |-> side.value,
         quoteCancelType                   |-> quoteCancelType.value,
         partyExecutingFirm                |-> partyExecutingFirm.value,
         partyExecutingTrader              |-> partyExecutingTrader.value,
         freeText5                         |-> freeText5.value,
         pad1                              |-> pad1.value,
         xetraEnLightTargetPartiesComp     |-> xetraEnLightTargetPartiesComp.value ], xetraEnLightTargetPartiesComp.rest)

ZeroXetraEnLightUpdateNegotiationRequest ==
    [ networkMsgId                      |-> [i \in 1 .. 8 |-> 0],
      pad2                              |-> [i \in 1 .. 2 |-> 0],
      requestHeaderComp                 |-> ZeroRequestHeaderComp37,
      bidPx                             |-> [i \in 1 .. 8 |-> 0],
      offerPx                           |-> [i \in 1 .. 8 |-> 0],
      orderQty                          |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId                   |-> [i \in 1 .. 4 |-> 0],
      negotiationId                     |-> [i \in 1 .. 4 |-> 0],
      settlDate                         |-> [i \in 1 .. 4 |-> 0],
      numberOfRespDisclosureInstruction |-> [i \in 1 .. 1 |-> 0],
      side                              |-> [i \in 1 .. 1 |-> 0],
      quoteCancelType                   |-> [i \in 1 .. 1 |-> 0],
      partyExecutingFirm                |-> [i \in 1 .. 5 |-> 0],
      partyExecutingTrader              |-> [i \in 1 .. 6 |-> 0],
      freeText5                         |-> [i \in 1 .. 132 |-> 0],
      pad1                              |-> [i \in 1 .. 1 |-> 0],
      xetraEnLightTargetPartiesComp     |-> << >> ]

(* Xetra En Light Update Negotiation Request at zero, then each field in turn at the values it is checked at *)
CheckedXetraEnLightUpdateNegotiationRequest ==
    { ZeroXetraEnLightUpdateNegotiationRequest }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.networkMsgId = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.pad2 = one] : one \in Sample(2) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.requestHeaderComp = one] : one \in CheckedRequestHeaderComp37 }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.negotiationId = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.numberOfRespDisclosureInstruction = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.quoteCancelType = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.partyExecutingFirm = one] : one \in Sample(5) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.partyExecutingTrader = one] : one \in Sample(6) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.freeText5 = one] : one \in Sample(132) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.pad1 = one] : one \in Sample(1) }
        \cup { [ZeroXetraEnLightUpdateNegotiationRequest EXCEPT !.xetraEnLightTargetPartiesComp = one] : one \in SampleLists(OneXetraEnLightTargetPartiesComp2) }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

ApproveTesTradeRequestCode == 10603  \* 0x296b
CrossRequestCode == 10118  \* 0x2786
DeleteAllOrderRequestCode == 10120  \* 0x2788
DeleteAllQuoteRequestCode == 10408  \* 0x28a8
DeleteOrderSingleRequestCode == 10109  \* 0x277d
DeleteTesTradeRequestCode == 10602  \* 0x296a
EnterTesTradeRequestCode == 10600  \* 0x2968
HeartbeatCode == 10011  \* 0x271b
InquireEnrichmentRuleIdListRequestCode == 10040  \* 0x2738
InquireSessionListRequestCode == 10035  \* 0x2733
InquireUserRequestCode == 10038  \* 0x2736
IssuerSecurityStateChangeRequestCode == 10314  \* 0x284a
LogonRequestCode == 10000  \* 0x2710
LogoutRequestCode == 10002  \* 0x2712
MassQuoteRequestCode == 10405  \* 0x28a5
ModifyOrderSingleRequestCode == 10106  \* 0x277a
ModifyOrderSingleShortRequestCode == 10126  \* 0x278e
ModifyTesTradeRequestCode == 10601  \* 0x2969
NewOrderSingleRequestCode == 10100  \* 0x2774
NewOrderSingleShortRequestCode == 10125  \* 0x278d
PingRequestCode == 10320  \* 0x2850
QuoteActivationRequestCode == 10403  \* 0x28a3
RfqRequestCode == 10401  \* 0x28a1
RetransmitMeMessageRequestCode == 10026  \* 0x272a
RetransmitRequestCode == 10008  \* 0x2718
SingleQuoteRequestCode == 10418  \* 0x28b2
SpecialistRfqRejectRequestCode == 10421  \* 0x28b5
SpecialistRfqReplyRequestCode == 10422  \* 0x28b6
SpecialistSecurityStateChangeRequestCode == 10317  \* 0x284d
SubscribeRequestCode == 10025  \* 0x2729
UnsubscribeRequestCode == 10006  \* 0x2716
UserLoginRequestCode == 10018  \* 0x2722
UserLogoutRequestCode == 10029  \* 0x272d
XetraEnLightEnterQuoteRequestCode == 10802  \* 0x2a32
XetraEnLightHitQuoteRequestCode == 10804  \* 0x2a34
XetraEnLightOpenNegotiationRequestCode == 10800  \* 0x2a30
XetraEnLightQuotingStatusRequestCode == 10817  \* 0x2a41
XetraEnLightUpdateNegotiationRequestCode == 10801  \* 0x2a31

ClientPayload ==
    [ tag : {ApproveTesTradeRequestCode}, body : ApproveTesTradeRequest ]
        \cup [ tag : {CrossRequestCode}, body : CrossRequest ]
        \cup [ tag : {DeleteAllOrderRequestCode}, body : DeleteAllOrderRequest ]
        \cup [ tag : {DeleteAllQuoteRequestCode}, body : DeleteAllQuoteRequest ]
        \cup [ tag : {DeleteOrderSingleRequestCode}, body : DeleteOrderSingleRequest ]
        \cup [ tag : {DeleteTesTradeRequestCode}, body : DeleteTesTradeRequest ]
        \cup [ tag : {EnterTesTradeRequestCode}, body : EnterTesTradeRequest ]
        \cup [ tag : {HeartbeatCode}, body : Heartbeat ]
        \cup [ tag : {InquireEnrichmentRuleIdListRequestCode}, body : InquireEnrichmentRuleIdListRequest ]
        \cup [ tag : {InquireSessionListRequestCode}, body : InquireSessionListRequest ]
        \cup [ tag : {InquireUserRequestCode}, body : InquireUserRequest ]
        \cup [ tag : {IssuerSecurityStateChangeRequestCode}, body : IssuerSecurityStateChangeRequest ]
        \cup [ tag : {LogonRequestCode}, body : LogonRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {MassQuoteRequestCode}, body : MassQuoteRequest ]
        \cup [ tag : {ModifyOrderSingleRequestCode}, body : ModifyOrderSingleRequest ]
        \cup [ tag : {ModifyOrderSingleShortRequestCode}, body : ModifyOrderSingleShortRequest ]
        \cup [ tag : {ModifyTesTradeRequestCode}, body : ModifyTesTradeRequest ]
        \cup [ tag : {NewOrderSingleRequestCode}, body : NewOrderSingleRequest ]
        \cup [ tag : {NewOrderSingleShortRequestCode}, body : NewOrderSingleShortRequest ]
        \cup [ tag : {PingRequestCode}, body : PingRequest ]
        \cup [ tag : {QuoteActivationRequestCode}, body : QuoteActivationRequest ]
        \cup [ tag : {RfqRequestCode}, body : RfqRequest ]
        \cup [ tag : {RetransmitMeMessageRequestCode}, body : RetransmitMeMessageRequest ]
        \cup [ tag : {RetransmitRequestCode}, body : RetransmitRequest ]
        \cup [ tag : {SingleQuoteRequestCode}, body : SingleQuoteRequest ]
        \cup [ tag : {SpecialistRfqRejectRequestCode}, body : SpecialistRfqRejectRequest ]
        \cup [ tag : {SpecialistRfqReplyRequestCode}, body : SpecialistRfqReplyRequest ]
        \cup [ tag : {SpecialistSecurityStateChangeRequestCode}, body : SpecialistSecurityStateChangeRequest ]
        \cup [ tag : {SubscribeRequestCode}, body : SubscribeRequest ]
        \cup [ tag : {UnsubscribeRequestCode}, body : UnsubscribeRequest ]
        \cup [ tag : {UserLoginRequestCode}, body : UserLoginRequest ]
        \cup [ tag : {UserLogoutRequestCode}, body : UserLogoutRequest ]
        \cup [ tag : {XetraEnLightEnterQuoteRequestCode}, body : XetraEnLightEnterQuoteRequest ]
        \cup [ tag : {XetraEnLightHitQuoteRequestCode}, body : XetraEnLightHitQuoteRequest ]
        \cup [ tag : {XetraEnLightOpenNegotiationRequestCode}, body : XetraEnLightOpenNegotiationRequest ]
        \cup [ tag : {XetraEnLightQuotingStatusRequestCode}, body : XetraEnLightQuotingStatusRequest ]
        \cup [ tag : {XetraEnLightUpdateNegotiationRequestCode}, body : XetraEnLightUpdateNegotiationRequest ]

EncodeClientPayload(message) ==
    CASE message.tag = ApproveTesTradeRequestCode -> EncodeApproveTesTradeRequest(message.body)
      [] message.tag = CrossRequestCode -> EncodeCrossRequest(message.body)
      [] message.tag = DeleteAllOrderRequestCode -> EncodeDeleteAllOrderRequest(message.body)
      [] message.tag = DeleteAllQuoteRequestCode -> EncodeDeleteAllQuoteRequest(message.body)
      [] message.tag = DeleteOrderSingleRequestCode -> EncodeDeleteOrderSingleRequest(message.body)
      [] message.tag = DeleteTesTradeRequestCode -> EncodeDeleteTesTradeRequest(message.body)
      [] message.tag = EnterTesTradeRequestCode -> EncodeEnterTesTradeRequest(message.body)
      [] message.tag = HeartbeatCode -> EncodeHeartbeat(message.body)
      [] message.tag = InquireEnrichmentRuleIdListRequestCode -> EncodeInquireEnrichmentRuleIdListRequest(message.body)
      [] message.tag = InquireSessionListRequestCode -> EncodeInquireSessionListRequest(message.body)
      [] message.tag = InquireUserRequestCode -> EncodeInquireUserRequest(message.body)
      [] message.tag = IssuerSecurityStateChangeRequestCode -> EncodeIssuerSecurityStateChangeRequest(message.body)
      [] message.tag = LogonRequestCode -> EncodeLogonRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = MassQuoteRequestCode -> EncodeMassQuoteRequest(message.body)
      [] message.tag = ModifyOrderSingleRequestCode -> EncodeModifyOrderSingleRequest(message.body)
      [] message.tag = ModifyOrderSingleShortRequestCode -> EncodeModifyOrderSingleShortRequest(message.body)
      [] message.tag = ModifyTesTradeRequestCode -> EncodeModifyTesTradeRequest(message.body)
      [] message.tag = NewOrderSingleRequestCode -> EncodeNewOrderSingleRequest(message.body)
      [] message.tag = NewOrderSingleShortRequestCode -> EncodeNewOrderSingleShortRequest(message.body)
      [] message.tag = PingRequestCode -> EncodePingRequest(message.body)
      [] message.tag = QuoteActivationRequestCode -> EncodeQuoteActivationRequest(message.body)
      [] message.tag = RfqRequestCode -> EncodeRfqRequest(message.body)
      [] message.tag = RetransmitMeMessageRequestCode -> EncodeRetransmitMeMessageRequest(message.body)
      [] message.tag = RetransmitRequestCode -> EncodeRetransmitRequest(message.body)
      [] message.tag = SingleQuoteRequestCode -> EncodeSingleQuoteRequest(message.body)
      [] message.tag = SpecialistRfqRejectRequestCode -> EncodeSpecialistRfqRejectRequest(message.body)
      [] message.tag = SpecialistRfqReplyRequestCode -> EncodeSpecialistRfqReplyRequest(message.body)
      [] message.tag = SpecialistSecurityStateChangeRequestCode -> EncodeSpecialistSecurityStateChangeRequest(message.body)
      [] message.tag = SubscribeRequestCode -> EncodeSubscribeRequest(message.body)
      [] message.tag = UnsubscribeRequestCode -> EncodeUnsubscribeRequest(message.body)
      [] message.tag = UserLoginRequestCode -> EncodeUserLoginRequest(message.body)
      [] message.tag = UserLogoutRequestCode -> EncodeUserLogoutRequest(message.body)
      [] message.tag = XetraEnLightEnterQuoteRequestCode -> EncodeXetraEnLightEnterQuoteRequest(message.body)
      [] message.tag = XetraEnLightHitQuoteRequestCode -> EncodeXetraEnLightHitQuoteRequest(message.body)
      [] message.tag = XetraEnLightOpenNegotiationRequestCode -> EncodeXetraEnLightOpenNegotiationRequest(message.body)
      [] message.tag = XetraEnLightQuotingStatusRequestCode -> EncodeXetraEnLightQuotingStatusRequest(message.body)
      [] message.tag = XetraEnLightUpdateNegotiationRequestCode -> EncodeXetraEnLightUpdateNegotiationRequest(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = ApproveTesTradeRequestCode -> DecodeApproveTesTradeRequest(bytes)
              [] tag = CrossRequestCode -> DecodeCrossRequest(bytes)
              [] tag = DeleteAllOrderRequestCode -> DecodeDeleteAllOrderRequest(bytes)
              [] tag = DeleteAllQuoteRequestCode -> DecodeDeleteAllQuoteRequest(bytes)
              [] tag = DeleteOrderSingleRequestCode -> DecodeDeleteOrderSingleRequest(bytes)
              [] tag = DeleteTesTradeRequestCode -> DecodeDeleteTesTradeRequest(bytes)
              [] tag = EnterTesTradeRequestCode -> DecodeEnterTesTradeRequest(bytes)
              [] tag = HeartbeatCode -> DecodeHeartbeat(bytes)
              [] tag = InquireEnrichmentRuleIdListRequestCode -> DecodeInquireEnrichmentRuleIdListRequest(bytes)
              [] tag = InquireSessionListRequestCode -> DecodeInquireSessionListRequest(bytes)
              [] tag = InquireUserRequestCode -> DecodeInquireUserRequest(bytes)
              [] tag = IssuerSecurityStateChangeRequestCode -> DecodeIssuerSecurityStateChangeRequest(bytes)
              [] tag = LogonRequestCode -> DecodeLogonRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = MassQuoteRequestCode -> DecodeMassQuoteRequest(bytes)
              [] tag = ModifyOrderSingleRequestCode -> DecodeModifyOrderSingleRequest(bytes)
              [] tag = ModifyOrderSingleShortRequestCode -> DecodeModifyOrderSingleShortRequest(bytes)
              [] tag = ModifyTesTradeRequestCode -> DecodeModifyTesTradeRequest(bytes)
              [] tag = NewOrderSingleRequestCode -> DecodeNewOrderSingleRequest(bytes)
              [] tag = NewOrderSingleShortRequestCode -> DecodeNewOrderSingleShortRequest(bytes)
              [] tag = PingRequestCode -> DecodePingRequest(bytes)
              [] tag = QuoteActivationRequestCode -> DecodeQuoteActivationRequest(bytes)
              [] tag = RfqRequestCode -> DecodeRfqRequest(bytes)
              [] tag = RetransmitMeMessageRequestCode -> DecodeRetransmitMeMessageRequest(bytes)
              [] tag = RetransmitRequestCode -> DecodeRetransmitRequest(bytes)
              [] tag = SingleQuoteRequestCode -> DecodeSingleQuoteRequest(bytes)
              [] tag = SpecialistRfqRejectRequestCode -> DecodeSpecialistRfqRejectRequest(bytes)
              [] tag = SpecialistRfqReplyRequestCode -> DecodeSpecialistRfqReplyRequest(bytes)
              [] tag = SpecialistSecurityStateChangeRequestCode -> DecodeSpecialistSecurityStateChangeRequest(bytes)
              [] tag = SubscribeRequestCode -> DecodeSubscribeRequest(bytes)
              [] tag = UnsubscribeRequestCode -> DecodeUnsubscribeRequest(bytes)
              [] tag = UserLoginRequestCode -> DecodeUserLoginRequest(bytes)
              [] tag = UserLogoutRequestCode -> DecodeUserLogoutRequest(bytes)
              [] tag = XetraEnLightEnterQuoteRequestCode -> DecodeXetraEnLightEnterQuoteRequest(bytes)
              [] tag = XetraEnLightHitQuoteRequestCode -> DecodeXetraEnLightHitQuoteRequest(bytes)
              [] tag = XetraEnLightOpenNegotiationRequestCode -> DecodeXetraEnLightOpenNegotiationRequest(bytes)
              [] tag = XetraEnLightQuotingStatusRequestCode -> DecodeXetraEnLightQuotingStatusRequest(bytes)
              [] tag = XetraEnLightUpdateNegotiationRequestCode -> DecodeXetraEnLightUpdateNegotiationRequest(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> ApproveTesTradeRequestCode, body |-> ZeroApproveTesTradeRequest]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> ApproveTesTradeRequestCode, body |-> one] : one \in CheckedApproveTesTradeRequest }
        \cup { [tag |-> CrossRequestCode, body |-> one] : one \in CheckedCrossRequest }
        \cup { [tag |-> DeleteAllOrderRequestCode, body |-> one] : one \in CheckedDeleteAllOrderRequest }
        \cup { [tag |-> DeleteAllQuoteRequestCode, body |-> one] : one \in CheckedDeleteAllQuoteRequest }
        \cup { [tag |-> DeleteOrderSingleRequestCode, body |-> one] : one \in CheckedDeleteOrderSingleRequest }
        \cup { [tag |-> DeleteTesTradeRequestCode, body |-> one] : one \in CheckedDeleteTesTradeRequest }
        \cup { [tag |-> EnterTesTradeRequestCode, body |-> one] : one \in CheckedEnterTesTradeRequest }
        \cup { [tag |-> HeartbeatCode, body |-> one] : one \in CheckedHeartbeat }
        \cup { [tag |-> InquireEnrichmentRuleIdListRequestCode, body |-> one] : one \in CheckedInquireEnrichmentRuleIdListRequest }
        \cup { [tag |-> InquireSessionListRequestCode, body |-> one] : one \in CheckedInquireSessionListRequest }
        \cup { [tag |-> InquireUserRequestCode, body |-> one] : one \in CheckedInquireUserRequest }
        \cup { [tag |-> IssuerSecurityStateChangeRequestCode, body |-> one] : one \in CheckedIssuerSecurityStateChangeRequest }
        \cup { [tag |-> LogonRequestCode, body |-> one] : one \in CheckedLogonRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> MassQuoteRequestCode, body |-> one] : one \in CheckedMassQuoteRequest }
        \cup { [tag |-> ModifyOrderSingleRequestCode, body |-> one] : one \in CheckedModifyOrderSingleRequest }
        \cup { [tag |-> ModifyOrderSingleShortRequestCode, body |-> one] : one \in CheckedModifyOrderSingleShortRequest }
        \cup { [tag |-> ModifyTesTradeRequestCode, body |-> one] : one \in CheckedModifyTesTradeRequest }
        \cup { [tag |-> NewOrderSingleRequestCode, body |-> one] : one \in CheckedNewOrderSingleRequest }
        \cup { [tag |-> NewOrderSingleShortRequestCode, body |-> one] : one \in CheckedNewOrderSingleShortRequest }
        \cup { [tag |-> PingRequestCode, body |-> one] : one \in CheckedPingRequest }
        \cup { [tag |-> QuoteActivationRequestCode, body |-> one] : one \in CheckedQuoteActivationRequest }
        \cup { [tag |-> RfqRequestCode, body |-> one] : one \in CheckedRfqRequest }
        \cup { [tag |-> RetransmitMeMessageRequestCode, body |-> one] : one \in CheckedRetransmitMeMessageRequest }
        \cup { [tag |-> RetransmitRequestCode, body |-> one] : one \in CheckedRetransmitRequest }
        \cup { [tag |-> SingleQuoteRequestCode, body |-> one] : one \in CheckedSingleQuoteRequest }
        \cup { [tag |-> SpecialistRfqRejectRequestCode, body |-> one] : one \in CheckedSpecialistRfqRejectRequest }
        \cup { [tag |-> SpecialistRfqReplyRequestCode, body |-> one] : one \in CheckedSpecialistRfqReplyRequest }
        \cup { [tag |-> SpecialistSecurityStateChangeRequestCode, body |-> one] : one \in CheckedSpecialistSecurityStateChangeRequest }
        \cup { [tag |-> SubscribeRequestCode, body |-> one] : one \in CheckedSubscribeRequest }
        \cup { [tag |-> UnsubscribeRequestCode, body |-> one] : one \in CheckedUnsubscribeRequest }
        \cup { [tag |-> UserLoginRequestCode, body |-> one] : one \in CheckedUserLoginRequest }
        \cup { [tag |-> UserLogoutRequestCode, body |-> one] : one \in CheckedUserLogoutRequest }
        \cup { [tag |-> XetraEnLightEnterQuoteRequestCode, body |-> one] : one \in CheckedXetraEnLightEnterQuoteRequest }
        \cup { [tag |-> XetraEnLightHitQuoteRequestCode, body |-> one] : one \in CheckedXetraEnLightHitQuoteRequest }
        \cup { [tag |-> XetraEnLightOpenNegotiationRequestCode, body |-> one] : one \in CheckedXetraEnLightOpenNegotiationRequest }
        \cup { [tag |-> XetraEnLightQuotingStatusRequestCode, body |-> one] : one \in CheckedXetraEnLightQuotingStatusRequest }
        \cup { [tag |-> XetraEnLightUpdateNegotiationRequestCode, body |-> one] : one \in CheckedXetraEnLightUpdateNegotiationRequest }

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
    { [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ApproveTesTradeRequestCode, body |-> ZeroApproveTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> CrossRequestCode, body |-> ZeroCrossRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteAllOrderRequestCode, body |-> ZeroDeleteAllOrderRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteAllQuoteRequestCode, body |-> ZeroDeleteAllQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteOrderSingleRequestCode, body |-> ZeroDeleteOrderSingleRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> DeleteTesTradeRequestCode, body |-> ZeroDeleteTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> EnterTesTradeRequestCode, body |-> ZeroEnterTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> HeartbeatCode, body |-> ZeroHeartbeat]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireEnrichmentRuleIdListRequestCode, body |-> ZeroInquireEnrichmentRuleIdListRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireSessionListRequestCode, body |-> ZeroInquireSessionListRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> InquireUserRequestCode, body |-> ZeroInquireUserRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> IssuerSecurityStateChangeRequestCode, body |-> ZeroIssuerSecurityStateChangeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogonRequestCode, body |-> ZeroLogonRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> MassQuoteRequestCode, body |-> ZeroMassQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderSingleRequestCode, body |-> ZeroModifyOrderSingleRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyOrderSingleShortRequestCode, body |-> ZeroModifyOrderSingleShortRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> ModifyTesTradeRequestCode, body |-> ZeroModifyTesTradeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderSingleRequestCode, body |-> ZeroNewOrderSingleRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> NewOrderSingleShortRequestCode, body |-> ZeroNewOrderSingleShortRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> PingRequestCode, body |-> ZeroPingRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> QuoteActivationRequestCode, body |-> ZeroQuoteActivationRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RfqRequestCode, body |-> ZeroRfqRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmitMeMessageRequestCode, body |-> ZeroRetransmitMeMessageRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> RetransmitRequestCode, body |-> ZeroRetransmitRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SingleQuoteRequestCode, body |-> ZeroSingleQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SpecialistRfqRejectRequestCode, body |-> ZeroSpecialistRfqRejectRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SpecialistRfqReplyRequestCode, body |-> ZeroSpecialistRfqReplyRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SpecialistSecurityStateChangeRequestCode, body |-> ZeroSpecialistSecurityStateChangeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> SubscribeRequestCode, body |-> ZeroSubscribeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UnsubscribeRequestCode, body |-> ZeroUnsubscribeRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserLoginRequestCode, body |-> ZeroUserLoginRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> UserLogoutRequestCode, body |-> ZeroUserLogoutRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> XetraEnLightEnterQuoteRequestCode, body |-> ZeroXetraEnLightEnterQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> XetraEnLightHitQuoteRequestCode, body |-> ZeroXetraEnLightHitQuoteRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> XetraEnLightOpenNegotiationRequestCode, body |-> ZeroXetraEnLightOpenNegotiationRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> XetraEnLightQuotingStatusRequestCode, body |-> ZeroXetraEnLightQuotingStatusRequest]],
      [ZeroClientMessage EXCEPT !.clientPayload = [tag |-> XetraEnLightUpdateNegotiationRequestCode, body |-> ZeroXetraEnLightUpdateNegotiationRequest]] }

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

(* Every Approve Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripApproveTesTradeRequest ==
    \A message \in CheckedApproveTesTradeRequest :
        LET read == DecodeApproveTesTradeRequest(EncodeApproveTesTradeRequest(message))
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

(* Every Cross Request decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossRequest ==
    \A message \in CheckedCrossRequest :
        LET read == DecodeCrossRequest(EncodeCrossRequest(message))
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

(* Every Delete All Order Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllOrderRequest ==
    \A message \in CheckedDeleteAllOrderRequest :
        LET read == DecodeDeleteAllOrderRequest(EncodeDeleteAllOrderRequest(message))
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

(* Every Delete All Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteAllQuoteRequest ==
    \A message \in CheckedDeleteAllQuoteRequest :
        LET read == DecodeDeleteAllQuoteRequest(EncodeDeleteAllQuoteRequest(message))
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

(* Every Delete Tes Trade Request decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteTesTradeRequest ==
    \A message \in CheckedDeleteTesTradeRequest :
        LET read == DecodeDeleteTesTradeRequest(EncodeDeleteTesTradeRequest(message))
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

(* Every Side Alloc Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSideAllocGrpComp ==
    \A message \in CheckedSideAllocGrpComp :
        LET read == DecodeSideAllocGrpComp(EncodeSideAllocGrpComp(message))
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

(* Every Heartbeat decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeat ==
    \A message \in CheckedHeartbeat :
        LET read == DecodeHeartbeat(EncodeHeartbeat(message))
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

(* Every Inquire Enrichment Rule Id List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireEnrichmentRuleIdListRequest ==
    \A message \in CheckedInquireEnrichmentRuleIdListRequest :
        LET read == DecodeInquireEnrichmentRuleIdListRequest(EncodeInquireEnrichmentRuleIdListRequest(message))
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

(* Every Inquire Session List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireSessionListRequest ==
    \A message \in CheckedInquireSessionListRequest :
        LET read == DecodeInquireSessionListRequest(EncodeInquireSessionListRequest(message))
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

(* Every Inquire User Request decodes back to what was encoded, and leaves nothing over *)
RoundTripInquireUserRequest ==
    \A message \in CheckedInquireUserRequest :
        LET read == DecodeInquireUserRequest(EncodeInquireUserRequest(message))
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

(* Every Security Status Event Grp Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusEventGrpComp ==
    \A message \in CheckedSecurityStatusEventGrpComp :
        LET read == DecodeSecurityStatusEventGrpComp(EncodeSecurityStatusEventGrpComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issuer Security State Change Request decodes back to what was encoded, and leaves nothing over *)
RoundTripIssuerSecurityStateChangeRequest ==
    \A message \in CheckedIssuerSecurityStateChangeRequest :
        LET read == DecodeIssuerSecurityStateChangeRequest(EncodeIssuerSecurityStateChangeRequest(message))
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

(* Every Logon Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequest ==
    \A message \in CheckedLogonRequest :
        LET read == DecodeLogonRequest(EncodeLogonRequest(message))
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

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
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
RoundTripRequestHeaderComp15 ==
    \A message \in CheckedRequestHeaderComp15 :
        LET read == DecodeRequestHeaderComp15(EncodeRequestHeaderComp15(message))
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
RoundTripRequestHeaderComp16 ==
    \A message \in CheckedRequestHeaderComp16 :
        LET read == DecodeRequestHeaderComp16(EncodeRequestHeaderComp16(message))
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
RoundTripRequestHeaderComp17 ==
    \A message \in CheckedRequestHeaderComp17 :
        LET read == DecodeRequestHeaderComp17(EncodeRequestHeaderComp17(message))
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
RoundTripRequestHeaderComp18 ==
    \A message \in CheckedRequestHeaderComp18 :
        LET read == DecodeRequestHeaderComp18(EncodeRequestHeaderComp18(message))
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
RoundTripRequestHeaderComp19 ==
    \A message \in CheckedRequestHeaderComp19 :
        LET read == DecodeRequestHeaderComp19(EncodeRequestHeaderComp19(message))
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
RoundTripRequestHeaderComp20 ==
    \A message \in CheckedRequestHeaderComp20 :
        LET read == DecodeRequestHeaderComp20(EncodeRequestHeaderComp20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ping Request decodes back to what was encoded, and leaves nothing over *)
RoundTripPingRequest ==
    \A message \in CheckedPingRequest :
        LET read == DecodePingRequest(EncodePingRequest(message))
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

(* Every Quote Activation Request decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteActivationRequest ==
    \A message \in CheckedQuoteActivationRequest :
        LET read == DecodeQuoteActivationRequest(EncodeQuoteActivationRequest(message))
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

(* Every Rfq Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqRequest ==
    \A message \in CheckedRfqRequest :
        LET read == DecodeRfqRequest(EncodeRfqRequest(message))
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

(* Every Retransmit Me Message Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitMeMessageRequest ==
    \A message \in CheckedRetransmitMeMessageRequest :
        LET read == DecodeRetransmitMeMessageRequest(EncodeRetransmitMeMessageRequest(message))
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

(* Every Retransmit Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRequest ==
    \A message \in CheckedRetransmitRequest :
        LET read == DecodeRetransmitRequest(EncodeRetransmitRequest(message))
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

(* Every Single Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleQuoteRequest ==
    \A message \in CheckedSingleQuoteRequest :
        LET read == DecodeSingleQuoteRequest(EncodeSingleQuoteRequest(message))
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

(* Every Specialist Rfq Reject Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialistRfqRejectRequest ==
    \A message \in CheckedSpecialistRfqRejectRequest :
        LET read == DecodeSpecialistRfqRejectRequest(EncodeSpecialistRfqRejectRequest(message))
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

(* Every Specialist Rfq Reply Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialistRfqReplyRequest ==
    \A message \in CheckedSpecialistRfqReplyRequest :
        LET read == DecodeSpecialistRfqReplyRequest(EncodeSpecialistRfqReplyRequest(message))
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

(* Every Specialist Security State Change Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialistSecurityStateChangeRequest ==
    \A message \in CheckedSpecialistSecurityStateChangeRequest :
        LET read == DecodeSpecialistSecurityStateChangeRequest(EncodeSpecialistSecurityStateChangeRequest(message))
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

(* Every Subscribe Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscribeRequest ==
    \A message \in CheckedSubscribeRequest :
        LET read == DecodeSubscribeRequest(EncodeSubscribeRequest(message))
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

(* Every Unsubscribe Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsubscribeRequest ==
    \A message \in CheckedUnsubscribeRequest :
        LET read == DecodeUnsubscribeRequest(EncodeUnsubscribeRequest(message))
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

(* Every User Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLoginRequest ==
    \A message \in CheckedUserLoginRequest :
        LET read == DecodeUserLoginRequest(EncodeUserLoginRequest(message))
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

(* Every User Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLogoutRequest ==
    \A message \in CheckedUserLogoutRequest :
        LET read == DecodeUserLogoutRequest(EncodeUserLogoutRequest(message))
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

(* Every Xetra En Light Enter Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightEnterQuoteRequest ==
    \A message \in CheckedXetraEnLightEnterQuoteRequest :
        LET read == DecodeXetraEnLightEnterQuoteRequest(EncodeXetraEnLightEnterQuoteRequest(message))
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

(* Every Xetra En Light Hit Quote Request decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightHitQuoteRequest ==
    \A message \in CheckedXetraEnLightHitQuoteRequest :
        LET read == DecodeXetraEnLightHitQuoteRequest(EncodeXetraEnLightHitQuoteRequest(message))
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

(* Every Xetra En Light Target Parties Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightTargetPartiesComp ==
    \A message \in CheckedXetraEnLightTargetPartiesComp :
        LET read == DecodeXetraEnLightTargetPartiesComp(EncodeXetraEnLightTargetPartiesComp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Open Negotiation Request decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightOpenNegotiationRequest ==
    \A message \in CheckedXetraEnLightOpenNegotiationRequest :
        LET read == DecodeXetraEnLightOpenNegotiationRequest(EncodeXetraEnLightOpenNegotiationRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp36 ==
    \A message \in CheckedRequestHeaderComp36 :
        LET read == DecodeRequestHeaderComp36(EncodeRequestHeaderComp36(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Xetra En Light Quoting Status Request decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightQuotingStatusRequest ==
    \A message \in CheckedXetraEnLightQuotingStatusRequest :
        LET read == DecodeXetraEnLightQuotingStatusRequest(EncodeXetraEnLightQuotingStatusRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Header Comp decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestHeaderComp37 ==
    \A message \in CheckedRequestHeaderComp37 :
        LET read == DecodeRequestHeaderComp37(EncodeRequestHeaderComp37(message))
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

(* Every Xetra En Light Update Negotiation Request decodes back to what was encoded, and leaves nothing over *)
RoundTripXetraEnLightUpdateNegotiationRequest ==
    \A message \in CheckedXetraEnLightUpdateNegotiationRequest :
        LET read == DecodeXetraEnLightUpdateNegotiationRequest(EncodeXetraEnLightUpdateNegotiationRequest(message))
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
