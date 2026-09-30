-------------- MODULE NasdaqCanada_OrderEntry_v5_0_1_4_Server --------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Nasdaq Canada Order Entry v5.0.1                               *)
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
(* Note: Appendage Length and what follows it are read only when the       *)
(* message runs on past what precedes them.                                *)
(*                                                                         *)
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ debugText : Sample(1) ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == ReadBytes(bytes, 1) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* System Event Message: 9 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp : Sample(8),
      eventCode : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         eventCode |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      eventCode |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx(message) ==
    message.userRefIdx

DecodeUserRefIdx(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx ==
    { ZeroUserRefIdx }
        \cup { [ZeroUserRefIdx EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Account: 15 bytes                                                       *)
(***************************************************************************)

Account ==
    [ account : Sample(15) ]

EncodeAccount(message) ==
    message.account

DecodeAccount(bytes) ==
    LET account == ReadBytes(bytes, 15) IN IF ~account.ok THEN Fail ELSE
    Ok([ account |-> account.value ], account.rest)

ZeroAccount ==
    [ account |-> [i \in 1 .. 15 |-> 0] ]

(* Account at zero, then each field in turn at the values it is checked at *)
CheckedAccount ==
    { ZeroAccount }
        \cup { [ZeroAccount EXCEPT !.account = one] : one \in Sample(15) }

(***************************************************************************)
(* Peg Type: 1 bytes                                                       *)
(***************************************************************************)

PegType ==
    [ pegType : Sample(1) ]

EncodePegType(message) ==
    message.pegType

DecodePegType(bytes) ==
    LET pegType == ReadBytes(bytes, 1) IN IF ~pegType.ok THEN Fail ELSE
    Ok([ pegType |-> pegType.value ], pegType.rest)

ZeroPegType ==
    [ pegType |-> [i \in 1 .. 1 |-> 0] ]

(* Peg Type at zero, then each field in turn at the values it is checked at *)
CheckedPegType ==
    { ZeroPegType }
        \cup { [ZeroPegType EXCEPT !.pegType = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Qty Type: 1 bytes                                                   *)
(***************************************************************************)

MinQtyType ==
    [ minQtyType : Sample(1) ]

EncodeMinQtyType(message) ==
    message.minQtyType

DecodeMinQtyType(bytes) ==
    LET minQtyType == ReadBytes(bytes, 1) IN IF ~minQtyType.ok THEN Fail ELSE
    Ok([ minQtyType |-> minQtyType.value ], minQtyType.rest)

ZeroMinQtyType ==
    [ minQtyType |-> [i \in 1 .. 1 |-> 0] ]

(* Min Qty Type at zero, then each field in turn at the values it is checked at *)
CheckedMinQtyType ==
    { ZeroMinQtyType }
        \cup { [ZeroMinQtyType EXCEPT !.minQtyType = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Qty: 4 bytes                                                        *)
(***************************************************************************)

MinQty ==
    [ minQty : Sample(4) ]

EncodeMinQty(message) ==
    message.minQty

DecodeMinQty(bytes) ==
    LET minQty == ReadBytes(bytes, 4) IN IF ~minQty.ok THEN Fail ELSE
    Ok([ minQty |-> minQty.value ], minQty.rest)

ZeroMinQty ==
    [ minQty |-> [i \in 1 .. 4 |-> 0] ]

(* Min Qty at zero, then each field in turn at the values it is checked at *)
CheckedMinQty ==
    { ZeroMinQty }
        \cup { [ZeroMinQty EXCEPT !.minQty = one] : one \in Sample(4) }

(***************************************************************************)
(* Max Floor: 4 bytes                                                      *)
(***************************************************************************)

MaxFloor ==
    [ maxFloor : Sample(4) ]

EncodeMaxFloor(message) ==
    message.maxFloor

DecodeMaxFloor(bytes) ==
    LET maxFloor == ReadBytes(bytes, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    Ok([ maxFloor |-> maxFloor.value ], maxFloor.rest)

ZeroMaxFloor ==
    [ maxFloor |-> [i \in 1 .. 4 |-> 0] ]

(* Max Floor at zero, then each field in turn at the values it is checked at *)
CheckedMaxFloor ==
    { ZeroMaxFloor }
        \cup { [ZeroMaxFloor EXCEPT !.maxFloor = one] : one \in Sample(4) }

(***************************************************************************)
(* Expire Time: 4 bytes                                                    *)
(***************************************************************************)

ExpireTime ==
    [ expireTime : Sample(4) ]

EncodeExpireTime(message) ==
    message.expireTime

DecodeExpireTime(bytes) ==
    LET expireTime == ReadBytes(bytes, 4) IN IF ~expireTime.ok THEN Fail ELSE
    Ok([ expireTime |-> expireTime.value ], expireTime.rest)

ZeroExpireTime ==
    [ expireTime |-> [i \in 1 .. 4 |-> 0] ]

(* Expire Time at zero, then each field in turn at the values it is checked at *)
CheckedExpireTime ==
    { ZeroExpireTime }
        \cup { [ZeroExpireTime EXCEPT !.expireTime = one] : one \in Sample(4) }

(***************************************************************************)
(* Peg Offset: 8 bytes                                                     *)
(***************************************************************************)

PegOffset ==
    [ pegOffset : Sample(8) ]

EncodePegOffset(message) ==
    message.pegOffset

DecodePegOffset(bytes) ==
    LET pegOffset == ReadBytes(bytes, 8) IN IF ~pegOffset.ok THEN Fail ELSE
    Ok([ pegOffset |-> pegOffset.value ], pegOffset.rest)

ZeroPegOffset ==
    [ pegOffset |-> [i \in 1 .. 8 |-> 0] ]

(* Peg Offset at zero, then each field in turn at the values it is checked at *)
CheckedPegOffset ==
    { ZeroPegOffset }
        \cup { [ZeroPegOffset EXCEPT !.pegOffset = one] : one \in Sample(8) }

(***************************************************************************)
(* Target Strategy: 2 bytes                                                *)
(***************************************************************************)

TargetStrategy ==
    [ targetStrategy : Sample(2) ]

EncodeTargetStrategy(message) ==
    message.targetStrategy

DecodeTargetStrategy(bytes) ==
    LET targetStrategy == ReadBytes(bytes, 2) IN IF ~targetStrategy.ok THEN Fail ELSE
    Ok([ targetStrategy |-> targetStrategy.value ], targetStrategy.rest)

ZeroTargetStrategy ==
    [ targetStrategy |-> [i \in 1 .. 2 |-> 0] ]

(* Target Strategy at zero, then each field in turn at the values it is checked at *)
CheckedTargetStrategy ==
    { ZeroTargetStrategy }
        \cup { [ZeroTargetStrategy EXCEPT !.targetStrategy = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Origination: 1 bytes                                              *)
(***************************************************************************)

OrderOrigination ==
    [ orderOrigination : Sample(1) ]

EncodeOrderOrigination(message) ==
    message.orderOrigination

DecodeOrderOrigination(bytes) ==
    LET orderOrigination == ReadBytes(bytes, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    Ok([ orderOrigination |-> orderOrigination.value ], orderOrigination.rest)

ZeroOrderOrigination ==
    [ orderOrigination |-> [i \in 1 .. 1 |-> 0] ]

(* Order Origination at zero, then each field in turn at the values it is checked at *)
CheckedOrderOrigination ==
    { ZeroOrderOrigination }
        \cup { [ZeroOrderOrigination EXCEPT !.orderOrigination = one] : one \in Sample(1) }

(***************************************************************************)
(* Routing Arrangement Indicator: 1 bytes                                  *)
(***************************************************************************)

RoutingArrangementIndicator ==
    [ routingArrangementIndicator : Sample(1) ]

EncodeRoutingArrangementIndicator(message) ==
    message.routingArrangementIndicator

DecodeRoutingArrangementIndicator(bytes) ==
    LET routingArrangementIndicator == ReadBytes(bytes, 1) IN IF ~routingArrangementIndicator.ok THEN Fail ELSE
    Ok([ routingArrangementIndicator |-> routingArrangementIndicator.value ], routingArrangementIndicator.rest)

ZeroRoutingArrangementIndicator ==
    [ routingArrangementIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Routing Arrangement Indicator at zero, then each field in turn at the values it is checked at *)
CheckedRoutingArrangementIndicator ==
    { ZeroRoutingArrangementIndicator }
        \cup { [ZeroRoutingArrangementIndicator EXCEPT !.routingArrangementIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Basket Trade: 1 bytes                                                   *)
(***************************************************************************)

BasketTrade ==
    [ basketTrade : Sample(1) ]

EncodeBasketTrade(message) ==
    message.basketTrade

DecodeBasketTrade(bytes) ==
    LET basketTrade == ReadBytes(bytes, 1) IN IF ~basketTrade.ok THEN Fail ELSE
    Ok([ basketTrade |-> basketTrade.value ], basketTrade.rest)

ZeroBasketTrade ==
    [ basketTrade |-> [i \in 1 .. 1 |-> 0] ]

(* Basket Trade at zero, then each field in turn at the values it is checked at *)
CheckedBasketTrade ==
    { ZeroBasketTrade }
        \cup { [ZeroBasketTrade EXCEPT !.basketTrade = one] : one \in Sample(1) }

(***************************************************************************)
(* Program Trade: 1 bytes                                                  *)
(***************************************************************************)

ProgramTrade ==
    [ programTrade : Sample(1) ]

EncodeProgramTrade(message) ==
    message.programTrade

DecodeProgramTrade(bytes) ==
    LET programTrade == ReadBytes(bytes, 1) IN IF ~programTrade.ok THEN Fail ELSE
    Ok([ programTrade |-> programTrade.value ], programTrade.rest)

ZeroProgramTrade ==
    [ programTrade |-> [i \in 1 .. 1 |-> 0] ]

(* Program Trade at zero, then each field in turn at the values it is checked at *)
CheckedProgramTrade ==
    { ZeroProgramTrade }
        \cup { [ZeroProgramTrade EXCEPT !.programTrade = one] : one \in Sample(1) }

(***************************************************************************)
(* Jitney: 3 bytes                                                         *)
(***************************************************************************)

Jitney ==
    [ jitney : Sample(3) ]

EncodeJitney(message) ==
    message.jitney

DecodeJitney(bytes) ==
    LET jitney == ReadBytes(bytes, 3) IN IF ~jitney.ok THEN Fail ELSE
    Ok([ jitney |-> jitney.value ], jitney.rest)

ZeroJitney ==
    [ jitney |-> [i \in 1 .. 3 |-> 0] ]

(* Jitney at zero, then each field in turn at the values it is checked at *)
CheckedJitney ==
    { ZeroJitney }
        \cup { [ZeroJitney EXCEPT !.jitney = one] : one \in Sample(3) }

(***************************************************************************)
(* Gef Eligible: 1 bytes                                                   *)
(***************************************************************************)

GefEligible ==
    [ gefEligible : Sample(1) ]

EncodeGefEligible(message) ==
    message.gefEligible

DecodeGefEligible(bytes) ==
    LET gefEligible == ReadBytes(bytes, 1) IN IF ~gefEligible.ok THEN Fail ELSE
    Ok([ gefEligible |-> gefEligible.value ], gefEligible.rest)

ZeroGefEligible ==
    [ gefEligible |-> [i \in 1 .. 1 |-> 0] ]

(* Gef Eligible at zero, then each field in turn at the values it is checked at *)
CheckedGefEligible ==
    { ZeroGefEligible }
        \cup { [ZeroGefEligible EXCEPT !.gefEligible = one] : one \in Sample(1) }

(***************************************************************************)
(* Anonymous: 1 bytes                                                      *)
(***************************************************************************)

Anonymous ==
    [ anonymous : Sample(1) ]

EncodeAnonymous(message) ==
    message.anonymous

DecodeAnonymous(bytes) ==
    LET anonymous == ReadBytes(bytes, 1) IN IF ~anonymous.ok THEN Fail ELSE
    Ok([ anonymous |-> anonymous.value ], anonymous.rest)

ZeroAnonymous ==
    [ anonymous |-> [i \in 1 .. 1 |-> 0] ]

(* Anonymous at zero, then each field in turn at the values it is checked at *)
CheckedAnonymous ==
    { ZeroAnonymous }
        \cup { [ZeroAnonymous EXCEPT !.anonymous = one] : one \in Sample(1) }

(***************************************************************************)
(* Umir Regulation Id: 2 bytes                                             *)
(***************************************************************************)

UmirRegulationId ==
    [ umirRegulationId : Sample(2) ]

EncodeUmirRegulationId(message) ==
    message.umirRegulationId

DecodeUmirRegulationId(bytes) ==
    LET umirRegulationId == ReadBytes(bytes, 2) IN IF ~umirRegulationId.ok THEN Fail ELSE
    Ok([ umirRegulationId |-> umirRegulationId.value ], umirRegulationId.rest)

ZeroUmirRegulationId ==
    [ umirRegulationId |-> [i \in 1 .. 2 |-> 0] ]

(* Umir Regulation Id at zero, then each field in turn at the values it is checked at *)
CheckedUmirRegulationId ==
    { ZeroUmirRegulationId }
        \cup { [ZeroUmirRegulationId EXCEPT !.umirRegulationId = one] : one \in Sample(2) }

(***************************************************************************)
(* Bypass: 1 bytes                                                         *)
(***************************************************************************)

Bypass ==
    [ bypass : Sample(1) ]

EncodeBypass(message) ==
    message.bypass

DecodeBypass(bytes) ==
    LET bypass == ReadBytes(bytes, 1) IN IF ~bypass.ok THEN Fail ELSE
    Ok([ bypass |-> bypass.value ], bypass.rest)

ZeroBypass ==
    [ bypass |-> [i \in 1 .. 1 |-> 0] ]

(* Bypass at zero, then each field in turn at the values it is checked at *)
CheckedBypass ==
    { ZeroBypass }
        \cup { [ZeroBypass EXCEPT !.bypass = one] : one \in Sample(1) }

(***************************************************************************)
(* Tsxncib: 1 bytes                                                        *)
(***************************************************************************)

Tsxncib ==
    [ tsxncib : Sample(1) ]

EncodeTsxncib(message) ==
    message.tsxncib

DecodeTsxncib(bytes) ==
    LET tsxncib == ReadBytes(bytes, 1) IN IF ~tsxncib.ok THEN Fail ELSE
    Ok([ tsxncib |-> tsxncib.value ], tsxncib.rest)

ZeroTsxncib ==
    [ tsxncib |-> [i \in 1 .. 1 |-> 0] ]

(* Tsxncib at zero, then each field in turn at the values it is checked at *)
CheckedTsxncib ==
    { ZeroTsxncib }
        \cup { [ZeroTsxncib EXCEPT !.tsxncib = one] : one \in Sample(1) }

(***************************************************************************)
(* No Trade Feat: 1 bytes                                                  *)
(***************************************************************************)

NoTradeFeat ==
    [ noTradeFeat : Sample(1) ]

EncodeNoTradeFeat(message) ==
    message.noTradeFeat

DecodeNoTradeFeat(bytes) ==
    LET noTradeFeat == ReadBytes(bytes, 1) IN IF ~noTradeFeat.ok THEN Fail ELSE
    Ok([ noTradeFeat |-> noTradeFeat.value ], noTradeFeat.rest)

ZeroNoTradeFeat ==
    [ noTradeFeat |-> [i \in 1 .. 1 |-> 0] ]

(* No Trade Feat at zero, then each field in turn at the values it is checked at *)
CheckedNoTradeFeat ==
    { ZeroNoTradeFeat }
        \cup { [ZeroNoTradeFeat EXCEPT !.noTradeFeat = one] : one \in Sample(1) }

(***************************************************************************)
(* No Trade Key: 6 bytes                                                   *)
(***************************************************************************)

NoTradeKey ==
    [ noTradeKey : Sample(6) ]

EncodeNoTradeKey(message) ==
    message.noTradeKey

DecodeNoTradeKey(bytes) ==
    LET noTradeKey == ReadBytes(bytes, 6) IN IF ~noTradeKey.ok THEN Fail ELSE
    Ok([ noTradeKey |-> noTradeKey.value ], noTradeKey.rest)

ZeroNoTradeKey ==
    [ noTradeKey |-> [i \in 1 .. 6 |-> 0] ]

(* No Trade Key at zero, then each field in turn at the values it is checked at *)
CheckedNoTradeKey ==
    { ZeroNoTradeKey }
        \cup { [ZeroNoTradeKey EXCEPT !.noTradeKey = one] : one \in Sample(6) }

(***************************************************************************)
(* Short Marking Exempt: 1 bytes                                           *)
(***************************************************************************)

ShortMarkingExempt ==
    [ shortMarkingExempt : Sample(1) ]

EncodeShortMarkingExempt(message) ==
    message.shortMarkingExempt

DecodeShortMarkingExempt(bytes) ==
    LET shortMarkingExempt == ReadBytes(bytes, 1) IN IF ~shortMarkingExempt.ok THEN Fail ELSE
    Ok([ shortMarkingExempt |-> shortMarkingExempt.value ], shortMarkingExempt.rest)

ZeroShortMarkingExempt ==
    [ shortMarkingExempt |-> [i \in 1 .. 1 |-> 0] ]

(* Short Marking Exempt at zero, then each field in turn at the values it is checked at *)
CheckedShortMarkingExempt ==
    { ZeroShortMarkingExempt }
        \cup { [ZeroShortMarkingExempt EXCEPT !.shortMarkingExempt = one] : one \in Sample(1) }

(***************************************************************************)
(* Po Comment: 32 bytes                                                    *)
(***************************************************************************)

PoComment ==
    [ poComment : Sample(32) ]

EncodePoComment(message) ==
    message.poComment

DecodePoComment(bytes) ==
    LET poComment == ReadBytes(bytes, 32) IN IF ~poComment.ok THEN Fail ELSE
    Ok([ poComment |-> poComment.value ], poComment.rest)

ZeroPoComment ==
    [ poComment |-> [i \in 1 .. 32 |-> 0] ]

(* Po Comment at zero, then each field in turn at the values it is checked at *)
CheckedPoComment ==
    { ZeroPoComment }
        \cup { [ZeroPoComment EXCEPT !.poComment = one] : one \in Sample(32) }

(***************************************************************************)
(* Display Range: 4 bytes                                                  *)
(***************************************************************************)

DisplayRange ==
    [ displayRange : Sample(4) ]

EncodeDisplayRange(message) ==
    message.displayRange

DecodeDisplayRange(bytes) ==
    LET displayRange == ReadBytes(bytes, 4) IN IF ~displayRange.ok THEN Fail ELSE
    Ok([ displayRange |-> displayRange.value ], displayRange.rest)

ZeroDisplayRange ==
    [ displayRange |-> [i \in 1 .. 4 |-> 0] ]

(* Display Range at zero, then each field in turn at the values it is checked at *)
CheckedDisplayRange ==
    { ZeroDisplayRange }
        \cup { [ZeroDisplayRange EXCEPT !.displayRange = one] : one \in Sample(4) }

(***************************************************************************)
(* Customer Account: 20 bytes                                              *)
(***************************************************************************)

CustomerAccount ==
    [ customerAccount : Sample(20) ]

EncodeCustomerAccount(message) ==
    message.customerAccount

DecodeCustomerAccount(bytes) ==
    LET customerAccount == ReadBytes(bytes, 20) IN IF ~customerAccount.ok THEN Fail ELSE
    Ok([ customerAccount |-> customerAccount.value ], customerAccount.rest)

ZeroCustomerAccount ==
    [ customerAccount |-> [i \in 1 .. 20 |-> 0] ]

(* Customer Account at zero, then each field in turn at the values it is checked at *)
CheckedCustomerAccount ==
    { ZeroCustomerAccount }
        \cup { [ZeroCustomerAccount EXCEPT !.customerAccount = one] : one \in Sample(20) }

(***************************************************************************)
(* Algorithm Id: 20 bytes                                                  *)
(***************************************************************************)

AlgorithmId ==
    [ algorithmId : Sample(20) ]

EncodeAlgorithmId(message) ==
    message.algorithmId

DecodeAlgorithmId(bytes) ==
    LET algorithmId == ReadBytes(bytes, 20) IN IF ~algorithmId.ok THEN Fail ELSE
    Ok([ algorithmId |-> algorithmId.value ], algorithmId.rest)

ZeroAlgorithmId ==
    [ algorithmId |-> [i \in 1 .. 20 |-> 0] ]

(* Algorithm Id at zero, then each field in turn at the values it is checked at *)
CheckedAlgorithmId ==
    { ZeroAlgorithmId }
        \cup { [ZeroAlgorithmId EXCEPT !.algorithmId = one] : one \in Sample(20) }

(***************************************************************************)
(* Customer Lei: 52 bytes                                                  *)
(***************************************************************************)

CustomerLei ==
    [ customerLei : Sample(52) ]

EncodeCustomerLei(message) ==
    message.customerLei

DecodeCustomerLei(bytes) ==
    LET customerLei == ReadBytes(bytes, 52) IN IF ~customerLei.ok THEN Fail ELSE
    Ok([ customerLei |-> customerLei.value ], customerLei.rest)

ZeroCustomerLei ==
    [ customerLei |-> [i \in 1 .. 52 |-> 0] ]

(* Customer Lei at zero, then each field in turn at the values it is checked at *)
CheckedCustomerLei ==
    { ZeroCustomerLei }
        \cup { [ZeroCustomerLei EXCEPT !.customerLei = one] : one \in Sample(52) }

(***************************************************************************)
(* Broker Lei: 20 bytes                                                    *)
(***************************************************************************)

BrokerLei ==
    [ brokerLei : Sample(20) ]

EncodeBrokerLei(message) ==
    message.brokerLei

DecodeBrokerLei(bytes) ==
    LET brokerLei == ReadBytes(bytes, 20) IN IF ~brokerLei.ok THEN Fail ELSE
    Ok([ brokerLei |-> brokerLei.value ], brokerLei.rest)

ZeroBrokerLei ==
    [ brokerLei |-> [i \in 1 .. 20 |-> 0] ]

(* Broker Lei at zero, then each field in turn at the values it is checked at *)
CheckedBrokerLei ==
    { ZeroBrokerLei }
        \cup { [ZeroBrokerLei EXCEPT !.brokerLei = one] : one \in Sample(20) }

(***************************************************************************)
(* Conditional Order: 1 bytes                                              *)
(***************************************************************************)

ConditionalOrder ==
    [ conditionalOrder : Sample(1) ]

EncodeConditionalOrder(message) ==
    message.conditionalOrder

DecodeConditionalOrder(bytes) ==
    LET conditionalOrder == ReadBytes(bytes, 1) IN IF ~conditionalOrder.ok THEN Fail ELSE
    Ok([ conditionalOrder |-> conditionalOrder.value ], conditionalOrder.rest)

ZeroConditionalOrder ==
    [ conditionalOrder |-> [i \in 1 .. 1 |-> 0] ]

(* Conditional Order at zero, then each field in turn at the values it is checked at *)
CheckedConditionalOrder ==
    { ZeroConditionalOrder }
        \cup { [ZeroConditionalOrder EXCEPT !.conditionalOrder = one] : one \in Sample(1) }

(***************************************************************************)
(* Allow Conditional: 1 bytes                                              *)
(***************************************************************************)

AllowConditional ==
    [ allowConditional : Sample(1) ]

EncodeAllowConditional(message) ==
    message.allowConditional

DecodeAllowConditional(bytes) ==
    LET allowConditional == ReadBytes(bytes, 1) IN IF ~allowConditional.ok THEN Fail ELSE
    Ok([ allowConditional |-> allowConditional.value ], allowConditional.rest)

ZeroAllowConditional ==
    [ allowConditional |-> [i \in 1 .. 1 |-> 0] ]

(* Allow Conditional at zero, then each field in turn at the values it is checked at *)
CheckedAllowConditional ==
    { ZeroAllowConditional }
        \cup { [ZeroAllowConditional EXCEPT !.allowConditional = one] : one \in Sample(1) }

(***************************************************************************)
(* Firm Up Id: 8 bytes                                                     *)
(***************************************************************************)

FirmUpId ==
    [ firmUpId : Sample(8) ]

EncodeFirmUpId(message) ==
    message.firmUpId

DecodeFirmUpId(bytes) ==
    LET firmUpId == ReadBytes(bytes, 8) IN IF ~firmUpId.ok THEN Fail ELSE
    Ok([ firmUpId |-> firmUpId.value ], firmUpId.rest)

ZeroFirmUpId ==
    [ firmUpId |-> [i \in 1 .. 8 |-> 0] ]

(* Firm Up Id at zero, then each field in turn at the values it is checked at *)
CheckedFirmUpId ==
    { ZeroFirmUpId }
        \cup { [ZeroFirmUpId EXCEPT !.firmUpId = one] : one \in Sample(8) }

(***************************************************************************)
(* Cxd Connect: 1 bytes                                                    *)
(***************************************************************************)

CxdConnect ==
    [ cxdConnect : Sample(1) ]

EncodeCxdConnect(message) ==
    message.cxdConnect

DecodeCxdConnect(bytes) ==
    LET cxdConnect == ReadBytes(bytes, 1) IN IF ~cxdConnect.ok THEN Fail ELSE
    Ok([ cxdConnect |-> cxdConnect.value ], cxdConnect.rest)

ZeroCxdConnect ==
    [ cxdConnect |-> [i \in 1 .. 1 |-> 0] ]

(* Cxd Connect at zero, then each field in turn at the values it is checked at *)
CheckedCxdConnect ==
    { ZeroCxdConnect }
        \cup { [ZeroCxdConnect EXCEPT !.cxdConnect = one] : one \in Sample(1) }

(***************************************************************************)
(* Pure Stream Connect: 1 bytes                                            *)
(***************************************************************************)

PureStreamConnect ==
    [ pureStreamConnect : Sample(1) ]

EncodePureStreamConnect(message) ==
    message.pureStreamConnect

DecodePureStreamConnect(bytes) ==
    LET pureStreamConnect == ReadBytes(bytes, 1) IN IF ~pureStreamConnect.ok THEN Fail ELSE
    Ok([ pureStreamConnect |-> pureStreamConnect.value ], pureStreamConnect.rest)

ZeroPureStreamConnect ==
    [ pureStreamConnect |-> [i \in 1 .. 1 |-> 0] ]

(* Pure Stream Connect at zero, then each field in turn at the values it is checked at *)
CheckedPureStreamConnect ==
    { ZeroPureStreamConnect }
        \cup { [ZeroPureStreamConnect EXCEPT !.pureStreamConnect = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Rate: 2 bytes                                                       *)
(***************************************************************************)

MinRate ==
    [ minRate : Sample(2) ]

EncodeMinRate(message) ==
    message.minRate

DecodeMinRate(bytes) ==
    LET minRate == ReadBytes(bytes, 2) IN IF ~minRate.ok THEN Fail ELSE
    Ok([ minRate |-> minRate.value ], minRate.rest)

ZeroMinRate ==
    [ minRate |-> [i \in 1 .. 2 |-> 0] ]

(* Min Rate at zero, then each field in turn at the values it is checked at *)
CheckedMinRate ==
    { ZeroMinRate }
        \cup { [ZeroMinRate EXCEPT !.minRate = one] : one \in Sample(2) }

(***************************************************************************)
(* Max Rate: 2 bytes                                                       *)
(***************************************************************************)

MaxRate ==
    [ maxRate : Sample(2) ]

EncodeMaxRate(message) ==
    message.maxRate

DecodeMaxRate(bytes) ==
    LET maxRate == ReadBytes(bytes, 2) IN IF ~maxRate.ok THEN Fail ELSE
    Ok([ maxRate |-> maxRate.value ], maxRate.rest)

ZeroMaxRate ==
    [ maxRate |-> [i \in 1 .. 2 |-> 0] ]

(* Max Rate at zero, then each field in turn at the values it is checked at *)
CheckedMaxRate ==
    { ZeroMaxRate }
        \cup { [ZeroMaxRate EXCEPT !.maxRate = one] : one \in Sample(2) }

(***************************************************************************)
(* Routing Strategy: 15 bytes                                              *)
(***************************************************************************)

RoutingStrategy ==
    [ routingStrategy : Sample(15) ]

EncodeRoutingStrategy(message) ==
    message.routingStrategy

DecodeRoutingStrategy(bytes) ==
    LET routingStrategy == ReadBytes(bytes, 15) IN IF ~routingStrategy.ok THEN Fail ELSE
    Ok([ routingStrategy |-> routingStrategy.value ], routingStrategy.rest)

ZeroRoutingStrategy ==
    [ routingStrategy |-> [i \in 1 .. 15 |-> 0] ]

(* Routing Strategy at zero, then each field in turn at the values it is checked at *)
CheckedRoutingStrategy ==
    { ZeroRoutingStrategy }
        \cup { [ZeroRoutingStrategy EXCEPT !.routingStrategy = one] : one \in Sample(15) }

(***************************************************************************)
(* Handl Inst: 1 bytes                                                     *)
(***************************************************************************)

HandlInst ==
    [ handlInst : Sample(1) ]

EncodeHandlInst(message) ==
    message.handlInst

DecodeHandlInst(bytes) ==
    LET handlInst == ReadBytes(bytes, 1) IN IF ~handlInst.ok THEN Fail ELSE
    Ok([ handlInst |-> handlInst.value ], handlInst.rest)

ZeroHandlInst ==
    [ handlInst |-> [i \in 1 .. 1 |-> 0] ]

(* Handl Inst at zero, then each field in turn at the values it is checked at *)
CheckedHandlInst ==
    { ZeroHandlInst }
        \cup { [ZeroHandlInst EXCEPT !.handlInst = one] : one \in Sample(1) }

(***************************************************************************)
(* Reprice Reason: 1 bytes                                                 *)
(***************************************************************************)

RepriceReason ==
    [ repriceReason : Sample(1) ]

EncodeRepriceReason(message) ==
    message.repriceReason

DecodeRepriceReason(bytes) ==
    LET repriceReason == ReadBytes(bytes, 1) IN IF ~repriceReason.ok THEN Fail ELSE
    Ok([ repriceReason |-> repriceReason.value ], repriceReason.rest)

ZeroRepriceReason ==
    [ repriceReason |-> [i \in 1 .. 1 |-> 0] ]

(* Reprice Reason at zero, then each field in turn at the values it is checked at *)
CheckedRepriceReason ==
    { ZeroRepriceReason }
        \cup { [ZeroRepriceReason EXCEPT !.repriceReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Nbbo Setter: 1 bytes                                                    *)
(***************************************************************************)

NbboSetter ==
    [ nbboSetter : Sample(1) ]

EncodeNbboSetter(message) ==
    message.nbboSetter

DecodeNbboSetter(bytes) ==
    LET nbboSetter == ReadBytes(bytes, 1) IN IF ~nbboSetter.ok THEN Fail ELSE
    Ok([ nbboSetter |-> nbboSetter.value ], nbboSetter.rest)

ZeroNbboSetter ==
    [ nbboSetter |-> [i \in 1 .. 1 |-> 0] ]

(* Nbbo Setter at zero, then each field in turn at the values it is checked at *)
CheckedNbboSetter ==
    { ZeroNbboSetter }
        \cup { [ZeroNbboSetter EXCEPT !.nbboSetter = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Accepted Optional Value, selected by Order Accepted Optional      *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode == 37  \* 0x25
AccountCode == 1  \* 0x01
PegTypeCode == 2  \* 0x02
MinQtyTypeCode == 3  \* 0x03
MinQtyCode == 4  \* 0x04
MaxFloorCode == 5  \* 0x05
ExpireTimeCode == 6  \* 0x06
PegOffsetCode == 7  \* 0x07
TargetStrategyCode == 8  \* 0x08
OrderOriginationCode == 9  \* 0x09
RoutingArrangementIndicatorCode == 10  \* 0x0a
BasketTradeCode == 11  \* 0x0b
ProgramTradeCode == 12  \* 0x0c
JitneyCode == 14  \* 0x0e
GefEligibleCode == 15  \* 0x0f
AnonymousCode == 16  \* 0x10
UmirRegulationIdCode == 17  \* 0x11
BypassCode == 18  \* 0x12
TsxncibCode == 19  \* 0x13
NoTradeFeatCode == 20  \* 0x14
NoTradeKeyCode == 21  \* 0x15
ShortMarkingExemptCode == 22  \* 0x16
PoCommentCode == 23  \* 0x17
DisplayRangeCode == 24  \* 0x18
CustomerAccountCode == 25  \* 0x19
AlgorithmIdCode == 26  \* 0x1a
CustomerLeiCode == 27  \* 0x1b
BrokerLeiCode == 28  \* 0x1c
ConditionalOrderCode == 29  \* 0x1d
AllowConditionalCode == 30  \* 0x1e
FirmUpIdCode == 31  \* 0x1f
CxdConnectCode == 32  \* 0x20
PureStreamConnectCode == 33  \* 0x21
MinRateCode == 34  \* 0x22
MaxRateCode == 35  \* 0x23
RoutingStrategyCode == 39  \* 0x27
HandlInstCode == 43  \* 0x2b
RepriceReasonCode == 44  \* 0x2c
NbboSetterCode == 45  \* 0x2d

OrderAcceptedOptionalValue ==
    [ tag : {UserRefIdxCode}, body : UserRefIdx ]
        \cup [ tag : {AccountCode}, body : Account ]
        \cup [ tag : {PegTypeCode}, body : PegType ]
        \cup [ tag : {MinQtyTypeCode}, body : MinQtyType ]
        \cup [ tag : {MinQtyCode}, body : MinQty ]
        \cup [ tag : {MaxFloorCode}, body : MaxFloor ]
        \cup [ tag : {ExpireTimeCode}, body : ExpireTime ]
        \cup [ tag : {PegOffsetCode}, body : PegOffset ]
        \cup [ tag : {TargetStrategyCode}, body : TargetStrategy ]
        \cup [ tag : {OrderOriginationCode}, body : OrderOrigination ]
        \cup [ tag : {RoutingArrangementIndicatorCode}, body : RoutingArrangementIndicator ]
        \cup [ tag : {BasketTradeCode}, body : BasketTrade ]
        \cup [ tag : {ProgramTradeCode}, body : ProgramTrade ]
        \cup [ tag : {JitneyCode}, body : Jitney ]
        \cup [ tag : {GefEligibleCode}, body : GefEligible ]
        \cup [ tag : {AnonymousCode}, body : Anonymous ]
        \cup [ tag : {UmirRegulationIdCode}, body : UmirRegulationId ]
        \cup [ tag : {BypassCode}, body : Bypass ]
        \cup [ tag : {TsxncibCode}, body : Tsxncib ]
        \cup [ tag : {NoTradeFeatCode}, body : NoTradeFeat ]
        \cup [ tag : {NoTradeKeyCode}, body : NoTradeKey ]
        \cup [ tag : {ShortMarkingExemptCode}, body : ShortMarkingExempt ]
        \cup [ tag : {PoCommentCode}, body : PoComment ]
        \cup [ tag : {DisplayRangeCode}, body : DisplayRange ]
        \cup [ tag : {CustomerAccountCode}, body : CustomerAccount ]
        \cup [ tag : {AlgorithmIdCode}, body : AlgorithmId ]
        \cup [ tag : {CustomerLeiCode}, body : CustomerLei ]
        \cup [ tag : {BrokerLeiCode}, body : BrokerLei ]
        \cup [ tag : {ConditionalOrderCode}, body : ConditionalOrder ]
        \cup [ tag : {AllowConditionalCode}, body : AllowConditional ]
        \cup [ tag : {FirmUpIdCode}, body : FirmUpId ]
        \cup [ tag : {CxdConnectCode}, body : CxdConnect ]
        \cup [ tag : {PureStreamConnectCode}, body : PureStreamConnect ]
        \cup [ tag : {MinRateCode}, body : MinRate ]
        \cup [ tag : {MaxRateCode}, body : MaxRate ]
        \cup [ tag : {RoutingStrategyCode}, body : RoutingStrategy ]
        \cup [ tag : {HandlInstCode}, body : HandlInst ]
        \cup [ tag : {RepriceReasonCode}, body : RepriceReason ]
        \cup [ tag : {NbboSetterCode}, body : NbboSetter ]

EncodeOrderAcceptedOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode -> EncodeUserRefIdx(message.body)
      [] message.tag = AccountCode -> EncodeAccount(message.body)
      [] message.tag = PegTypeCode -> EncodePegType(message.body)
      [] message.tag = MinQtyTypeCode -> EncodeMinQtyType(message.body)
      [] message.tag = MinQtyCode -> EncodeMinQty(message.body)
      [] message.tag = MaxFloorCode -> EncodeMaxFloor(message.body)
      [] message.tag = ExpireTimeCode -> EncodeExpireTime(message.body)
      [] message.tag = PegOffsetCode -> EncodePegOffset(message.body)
      [] message.tag = TargetStrategyCode -> EncodeTargetStrategy(message.body)
      [] message.tag = OrderOriginationCode -> EncodeOrderOrigination(message.body)
      [] message.tag = RoutingArrangementIndicatorCode -> EncodeRoutingArrangementIndicator(message.body)
      [] message.tag = BasketTradeCode -> EncodeBasketTrade(message.body)
      [] message.tag = ProgramTradeCode -> EncodeProgramTrade(message.body)
      [] message.tag = JitneyCode -> EncodeJitney(message.body)
      [] message.tag = GefEligibleCode -> EncodeGefEligible(message.body)
      [] message.tag = AnonymousCode -> EncodeAnonymous(message.body)
      [] message.tag = UmirRegulationIdCode -> EncodeUmirRegulationId(message.body)
      [] message.tag = BypassCode -> EncodeBypass(message.body)
      [] message.tag = TsxncibCode -> EncodeTsxncib(message.body)
      [] message.tag = NoTradeFeatCode -> EncodeNoTradeFeat(message.body)
      [] message.tag = NoTradeKeyCode -> EncodeNoTradeKey(message.body)
      [] message.tag = ShortMarkingExemptCode -> EncodeShortMarkingExempt(message.body)
      [] message.tag = PoCommentCode -> EncodePoComment(message.body)
      [] message.tag = DisplayRangeCode -> EncodeDisplayRange(message.body)
      [] message.tag = CustomerAccountCode -> EncodeCustomerAccount(message.body)
      [] message.tag = AlgorithmIdCode -> EncodeAlgorithmId(message.body)
      [] message.tag = CustomerLeiCode -> EncodeCustomerLei(message.body)
      [] message.tag = BrokerLeiCode -> EncodeBrokerLei(message.body)
      [] message.tag = ConditionalOrderCode -> EncodeConditionalOrder(message.body)
      [] message.tag = AllowConditionalCode -> EncodeAllowConditional(message.body)
      [] message.tag = FirmUpIdCode -> EncodeFirmUpId(message.body)
      [] message.tag = CxdConnectCode -> EncodeCxdConnect(message.body)
      [] message.tag = PureStreamConnectCode -> EncodePureStreamConnect(message.body)
      [] message.tag = MinRateCode -> EncodeMinRate(message.body)
      [] message.tag = MaxRateCode -> EncodeMaxRate(message.body)
      [] message.tag = RoutingStrategyCode -> EncodeRoutingStrategy(message.body)
      [] message.tag = HandlInstCode -> EncodeHandlInst(message.body)
      [] message.tag = RepriceReasonCode -> EncodeRepriceReason(message.body)
      [] message.tag = NbboSetterCode -> EncodeNbboSetter(message.body)

DecodeOrderAcceptedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode -> DecodeUserRefIdx(bytes)
              [] tag = AccountCode -> DecodeAccount(bytes)
              [] tag = PegTypeCode -> DecodePegType(bytes)
              [] tag = MinQtyTypeCode -> DecodeMinQtyType(bytes)
              [] tag = MinQtyCode -> DecodeMinQty(bytes)
              [] tag = MaxFloorCode -> DecodeMaxFloor(bytes)
              [] tag = ExpireTimeCode -> DecodeExpireTime(bytes)
              [] tag = PegOffsetCode -> DecodePegOffset(bytes)
              [] tag = TargetStrategyCode -> DecodeTargetStrategy(bytes)
              [] tag = OrderOriginationCode -> DecodeOrderOrigination(bytes)
              [] tag = RoutingArrangementIndicatorCode -> DecodeRoutingArrangementIndicator(bytes)
              [] tag = BasketTradeCode -> DecodeBasketTrade(bytes)
              [] tag = ProgramTradeCode -> DecodeProgramTrade(bytes)
              [] tag = JitneyCode -> DecodeJitney(bytes)
              [] tag = GefEligibleCode -> DecodeGefEligible(bytes)
              [] tag = AnonymousCode -> DecodeAnonymous(bytes)
              [] tag = UmirRegulationIdCode -> DecodeUmirRegulationId(bytes)
              [] tag = BypassCode -> DecodeBypass(bytes)
              [] tag = TsxncibCode -> DecodeTsxncib(bytes)
              [] tag = NoTradeFeatCode -> DecodeNoTradeFeat(bytes)
              [] tag = NoTradeKeyCode -> DecodeNoTradeKey(bytes)
              [] tag = ShortMarkingExemptCode -> DecodeShortMarkingExempt(bytes)
              [] tag = PoCommentCode -> DecodePoComment(bytes)
              [] tag = DisplayRangeCode -> DecodeDisplayRange(bytes)
              [] tag = CustomerAccountCode -> DecodeCustomerAccount(bytes)
              [] tag = AlgorithmIdCode -> DecodeAlgorithmId(bytes)
              [] tag = CustomerLeiCode -> DecodeCustomerLei(bytes)
              [] tag = BrokerLeiCode -> DecodeBrokerLei(bytes)
              [] tag = ConditionalOrderCode -> DecodeConditionalOrder(bytes)
              [] tag = AllowConditionalCode -> DecodeAllowConditional(bytes)
              [] tag = FirmUpIdCode -> DecodeFirmUpId(bytes)
              [] tag = CxdConnectCode -> DecodeCxdConnect(bytes)
              [] tag = PureStreamConnectCode -> DecodePureStreamConnect(bytes)
              [] tag = MinRateCode -> DecodeMinRate(bytes)
              [] tag = MaxRateCode -> DecodeMaxRate(bytes)
              [] tag = RoutingStrategyCode -> DecodeRoutingStrategy(bytes)
              [] tag = HandlInstCode -> DecodeHandlInst(bytes)
              [] tag = RepriceReasonCode -> DecodeRepriceReason(bytes)
              [] tag = NbboSetterCode -> DecodeNbboSetter(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderAcceptedOptionalValue == [tag |-> UserRefIdxCode, body |-> ZeroUserRefIdx]

(* Each Order Accepted Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderAcceptedOptionalValue ==
    { [tag |-> UserRefIdxCode, body |-> one] : one \in CheckedUserRefIdx }
        \cup { [tag |-> AccountCode, body |-> one] : one \in CheckedAccount }
        \cup { [tag |-> PegTypeCode, body |-> one] : one \in CheckedPegType }
        \cup { [tag |-> MinQtyTypeCode, body |-> one] : one \in CheckedMinQtyType }
        \cup { [tag |-> MinQtyCode, body |-> one] : one \in CheckedMinQty }
        \cup { [tag |-> MaxFloorCode, body |-> one] : one \in CheckedMaxFloor }
        \cup { [tag |-> ExpireTimeCode, body |-> one] : one \in CheckedExpireTime }
        \cup { [tag |-> PegOffsetCode, body |-> one] : one \in CheckedPegOffset }
        \cup { [tag |-> TargetStrategyCode, body |-> one] : one \in CheckedTargetStrategy }
        \cup { [tag |-> OrderOriginationCode, body |-> one] : one \in CheckedOrderOrigination }
        \cup { [tag |-> RoutingArrangementIndicatorCode, body |-> one] : one \in CheckedRoutingArrangementIndicator }
        \cup { [tag |-> BasketTradeCode, body |-> one] : one \in CheckedBasketTrade }
        \cup { [tag |-> ProgramTradeCode, body |-> one] : one \in CheckedProgramTrade }
        \cup { [tag |-> JitneyCode, body |-> one] : one \in CheckedJitney }
        \cup { [tag |-> GefEligibleCode, body |-> one] : one \in CheckedGefEligible }
        \cup { [tag |-> AnonymousCode, body |-> one] : one \in CheckedAnonymous }
        \cup { [tag |-> UmirRegulationIdCode, body |-> one] : one \in CheckedUmirRegulationId }
        \cup { [tag |-> BypassCode, body |-> one] : one \in CheckedBypass }
        \cup { [tag |-> TsxncibCode, body |-> one] : one \in CheckedTsxncib }
        \cup { [tag |-> NoTradeFeatCode, body |-> one] : one \in CheckedNoTradeFeat }
        \cup { [tag |-> NoTradeKeyCode, body |-> one] : one \in CheckedNoTradeKey }
        \cup { [tag |-> ShortMarkingExemptCode, body |-> one] : one \in CheckedShortMarkingExempt }
        \cup { [tag |-> PoCommentCode, body |-> one] : one \in CheckedPoComment }
        \cup { [tag |-> DisplayRangeCode, body |-> one] : one \in CheckedDisplayRange }
        \cup { [tag |-> CustomerAccountCode, body |-> one] : one \in CheckedCustomerAccount }
        \cup { [tag |-> AlgorithmIdCode, body |-> one] : one \in CheckedAlgorithmId }
        \cup { [tag |-> CustomerLeiCode, body |-> one] : one \in CheckedCustomerLei }
        \cup { [tag |-> BrokerLeiCode, body |-> one] : one \in CheckedBrokerLei }
        \cup { [tag |-> ConditionalOrderCode, body |-> one] : one \in CheckedConditionalOrder }
        \cup { [tag |-> AllowConditionalCode, body |-> one] : one \in CheckedAllowConditional }
        \cup { [tag |-> FirmUpIdCode, body |-> one] : one \in CheckedFirmUpId }
        \cup { [tag |-> CxdConnectCode, body |-> one] : one \in CheckedCxdConnect }
        \cup { [tag |-> PureStreamConnectCode, body |-> one] : one \in CheckedPureStreamConnect }
        \cup { [tag |-> MinRateCode, body |-> one] : one \in CheckedMinRate }
        \cup { [tag |-> MaxRateCode, body |-> one] : one \in CheckedMaxRate }
        \cup { [tag |-> RoutingStrategyCode, body |-> one] : one \in CheckedRoutingStrategy }
        \cup { [tag |-> HandlInstCode, body |-> one] : one \in CheckedHandlInst }
        \cup { [tag |-> RepriceReasonCode, body |-> one] : one \in CheckedRepriceReason }
        \cup { [tag |-> NbboSetterCode, body |-> one] : one \in CheckedNbboSetter }

(***************************************************************************)
(* Order Accepted Appendage, framed by Optional Field Length               *)
(***************************************************************************)

OrderAcceptedAppendage ==
    [ orderAcceptedOptionalValue : OrderAcceptedOptionalValue ]

EncodeOrderAcceptedAppendageBody(message) ==
    EncodeUIntBE(message.orderAcceptedOptionalValue.tag, 1)
        \o EncodeOrderAcceptedOptionalValue(message.orderAcceptedOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeOrderAcceptedAppendage(message) ==
    LET body == EncodeOrderAcceptedAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeOrderAcceptedAppendageBody(bytes) ==
    LET orderAcceptedOptionalField == ReadUIntBE(bytes, 1) IN IF ~orderAcceptedOptionalField.ok THEN Fail ELSE
    LET orderAcceptedOptionalValue == DecodeOrderAcceptedOptionalValue(orderAcceptedOptionalField.value, orderAcceptedOptionalField.rest) IN IF ~orderAcceptedOptionalValue.ok THEN Fail ELSE
    Ok([ orderAcceptedOptionalValue |-> orderAcceptedOptionalValue.value ], orderAcceptedOptionalValue.rest)

DecodeOrderAcceptedAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeOrderAcceptedAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroOrderAcceptedAppendage ==
    [ orderAcceptedOptionalValue |-> ZeroOrderAcceptedOptionalValue ]

(* Order Accepted Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcceptedAppendage ==
    { ZeroOrderAcceptedAppendage }
        \cup { [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = one] : one \in CheckedOrderAcceptedOptionalValue }

(* A run of Order Accepted Appendage, written one after another *)
RECURSIVE EncodeOrderAcceptedAppendageList(_)
EncodeOrderAcceptedAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderAcceptedAppendage(Head(messages)) \o EncodeOrderAcceptedAppendageList(Tail(messages))

(* As many Order Accepted Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadOrderAcceptedAppendageAll(_)
ReadOrderAcceptedAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeOrderAcceptedAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderAcceptedAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Accepted Appendage of each kind, for the lists that carry them *)
OneOrderAcceptedAppendage ==
    { [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> UserRefIdxCode, body |-> ZeroUserRefIdx]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> AccountCode, body |-> ZeroAccount]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> PegTypeCode, body |-> ZeroPegType]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> MinQtyTypeCode, body |-> ZeroMinQtyType]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> MinQtyCode, body |-> ZeroMinQty]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> MaxFloorCode, body |-> ZeroMaxFloor]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> ExpireTimeCode, body |-> ZeroExpireTime]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> PegOffsetCode, body |-> ZeroPegOffset]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> TargetStrategyCode, body |-> ZeroTargetStrategy]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> OrderOriginationCode, body |-> ZeroOrderOrigination]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> RoutingArrangementIndicatorCode, body |-> ZeroRoutingArrangementIndicator]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> BasketTradeCode, body |-> ZeroBasketTrade]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> ProgramTradeCode, body |-> ZeroProgramTrade]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> JitneyCode, body |-> ZeroJitney]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> GefEligibleCode, body |-> ZeroGefEligible]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> AnonymousCode, body |-> ZeroAnonymous]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> UmirRegulationIdCode, body |-> ZeroUmirRegulationId]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> BypassCode, body |-> ZeroBypass]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> TsxncibCode, body |-> ZeroTsxncib]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> NoTradeFeatCode, body |-> ZeroNoTradeFeat]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> NoTradeKeyCode, body |-> ZeroNoTradeKey]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> ShortMarkingExemptCode, body |-> ZeroShortMarkingExempt]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> PoCommentCode, body |-> ZeroPoComment]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> DisplayRangeCode, body |-> ZeroDisplayRange]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> CustomerAccountCode, body |-> ZeroCustomerAccount]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> AlgorithmIdCode, body |-> ZeroAlgorithmId]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> CustomerLeiCode, body |-> ZeroCustomerLei]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> BrokerLeiCode, body |-> ZeroBrokerLei]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> ConditionalOrderCode, body |-> ZeroConditionalOrder]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> AllowConditionalCode, body |-> ZeroAllowConditional]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> FirmUpIdCode, body |-> ZeroFirmUpId]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> CxdConnectCode, body |-> ZeroCxdConnect]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> PureStreamConnectCode, body |-> ZeroPureStreamConnect]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> MinRateCode, body |-> ZeroMinRate]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> MaxRateCode, body |-> ZeroMaxRate]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> RoutingStrategyCode, body |-> ZeroRoutingStrategy]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> HandlInstCode, body |-> ZeroHandlInst]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> RepriceReasonCode, body |-> ZeroRepriceReason]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> NbboSetterCode, body |-> ZeroNbboSetter]] }

(***************************************************************************)
(* Order Accepted Message                                                  *)
(***************************************************************************)

OrderAcceptedMessage ==
    [ timestamp              : Sample(8),
      userRefNum             : Sample(4),
      orderQty               : Sample(4),
      price                  : Sample(8),
      side                   : Sample(1),
      symbol                 : Sample(10),
      timeInForce            : Sample(1),
      exDestination          : Sample(1),
      umirAccountType        : Sample(2),
      umirUserId             : Sample(8),
      orderReferenceNumber   : Sample(8),
      orderState             : Sample(1),
      orderAcceptedAppendage : SampleLists(OneOrderAcceptedAppendage) ]

EncodeOrderAcceptedMessage(message) ==
    LET payload == EncodeOrderAcceptedAppendageList(message.orderAcceptedAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.orderQty
            \o message.price
            \o message.side
            \o message.symbol
            \o message.timeInForce
            \o message.exDestination
            \o message.umirAccountType
            \o message.umirUserId
            \o message.orderReferenceNumber
            \o message.orderState
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderAcceptedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET orderQty == ReadBytes(userRefNum.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET exDestination == ReadBytes(timeInForce.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET umirAccountType == ReadBytes(exDestination.rest, 2) IN IF ~umirAccountType.ok THEN Fail ELSE
    LET umirUserId == ReadBytes(umirAccountType.rest, 8) IN IF ~umirUserId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(umirUserId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET orderState == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(orderState.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        orderAcceptedAppendage == ReadOrderAcceptedAppendageAll(framed)
    IN  IF ~orderAcceptedAppendage.ok \/ orderAcceptedAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         userRefNum             |-> userRefNum.value,
         orderQty               |-> orderQty.value,
         price                  |-> price.value,
         side                   |-> side.value,
         symbol                 |-> symbol.value,
         timeInForce            |-> timeInForce.value,
         exDestination          |-> exDestination.value,
         umirAccountType        |-> umirAccountType.value,
         umirUserId             |-> umirUserId.value,
         orderReferenceNumber   |-> orderReferenceNumber.value,
         orderState             |-> orderState.value,
         orderAcceptedAppendage |-> orderAcceptedAppendage.value ], beyond)

ZeroOrderAcceptedMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      userRefNum             |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 10 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      exDestination          |-> [i \in 1 .. 1 |-> 0],
      umirAccountType        |-> [i \in 1 .. 2 |-> 0],
      umirUserId             |-> [i \in 1 .. 8 |-> 0],
      orderReferenceNumber   |-> [i \in 1 .. 8 |-> 0],
      orderState             |-> [i \in 1 .. 1 |-> 0],
      orderAcceptedAppendage |-> << >> ]

(* Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcceptedMessage ==
    { ZeroOrderAcceptedMessage }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.umirAccountType = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.umirUserId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderAcceptedAppendage = one] : one \in SampleLists(OneOrderAcceptedAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx2 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx2(message) ==
    message.userRefIdx

DecodeUserRefIdx2(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx2 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx2 ==
    { ZeroUserRefIdx2 }
        \cup { [ZeroUserRefIdx2 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Qty Type: 1 bytes                                                   *)
(***************************************************************************)

MinQtyType2 ==
    [ minQtyType : Sample(1) ]

EncodeMinQtyType2(message) ==
    message.minQtyType

DecodeMinQtyType2(bytes) ==
    LET minQtyType == ReadBytes(bytes, 1) IN IF ~minQtyType.ok THEN Fail ELSE
    Ok([ minQtyType |-> minQtyType.value ], minQtyType.rest)

ZeroMinQtyType2 ==
    [ minQtyType |-> [i \in 1 .. 1 |-> 0] ]

(* Min Qty Type at zero, then each field in turn at the values it is checked at *)
CheckedMinQtyType2 ==
    { ZeroMinQtyType2 }
        \cup { [ZeroMinQtyType2 EXCEPT !.minQtyType = one] : one \in Sample(1) }

(***************************************************************************)
(* Peg Type: 1 bytes                                                       *)
(***************************************************************************)

PegType2 ==
    [ pegType : Sample(1) ]

EncodePegType2(message) ==
    message.pegType

DecodePegType2(bytes) ==
    LET pegType == ReadBytes(bytes, 1) IN IF ~pegType.ok THEN Fail ELSE
    Ok([ pegType |-> pegType.value ], pegType.rest)

ZeroPegType2 ==
    [ pegType |-> [i \in 1 .. 1 |-> 0] ]

(* Peg Type at zero, then each field in turn at the values it is checked at *)
CheckedPegType2 ==
    { ZeroPegType2 }
        \cup { [ZeroPegType2 EXCEPT !.pegType = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Qty: 4 bytes                                                        *)
(***************************************************************************)

MinQty2 ==
    [ minQty : Sample(4) ]

EncodeMinQty2(message) ==
    message.minQty

DecodeMinQty2(bytes) ==
    LET minQty == ReadBytes(bytes, 4) IN IF ~minQty.ok THEN Fail ELSE
    Ok([ minQty |-> minQty.value ], minQty.rest)

ZeroMinQty2 ==
    [ minQty |-> [i \in 1 .. 4 |-> 0] ]

(* Min Qty at zero, then each field in turn at the values it is checked at *)
CheckedMinQty2 ==
    { ZeroMinQty2 }
        \cup { [ZeroMinQty2 EXCEPT !.minQty = one] : one \in Sample(4) }

(***************************************************************************)
(* Max Floor: 4 bytes                                                      *)
(***************************************************************************)

MaxFloor2 ==
    [ maxFloor : Sample(4) ]

EncodeMaxFloor2(message) ==
    message.maxFloor

DecodeMaxFloor2(bytes) ==
    LET maxFloor == ReadBytes(bytes, 4) IN IF ~maxFloor.ok THEN Fail ELSE
    Ok([ maxFloor |-> maxFloor.value ], maxFloor.rest)

ZeroMaxFloor2 ==
    [ maxFloor |-> [i \in 1 .. 4 |-> 0] ]

(* Max Floor at zero, then each field in turn at the values it is checked at *)
CheckedMaxFloor2 ==
    { ZeroMaxFloor2 }
        \cup { [ZeroMaxFloor2 EXCEPT !.maxFloor = one] : one \in Sample(4) }

(***************************************************************************)
(* Expire Time: 4 bytes                                                    *)
(***************************************************************************)

ExpireTime2 ==
    [ expireTime : Sample(4) ]

EncodeExpireTime2(message) ==
    message.expireTime

DecodeExpireTime2(bytes) ==
    LET expireTime == ReadBytes(bytes, 4) IN IF ~expireTime.ok THEN Fail ELSE
    Ok([ expireTime |-> expireTime.value ], expireTime.rest)

ZeroExpireTime2 ==
    [ expireTime |-> [i \in 1 .. 4 |-> 0] ]

(* Expire Time at zero, then each field in turn at the values it is checked at *)
CheckedExpireTime2 ==
    { ZeroExpireTime2 }
        \cup { [ZeroExpireTime2 EXCEPT !.expireTime = one] : one \in Sample(4) }

(***************************************************************************)
(* Peg Offset: 8 bytes                                                     *)
(***************************************************************************)

PegOffset2 ==
    [ pegOffset : Sample(8) ]

EncodePegOffset2(message) ==
    message.pegOffset

DecodePegOffset2(bytes) ==
    LET pegOffset == ReadBytes(bytes, 8) IN IF ~pegOffset.ok THEN Fail ELSE
    Ok([ pegOffset |-> pegOffset.value ], pegOffset.rest)

ZeroPegOffset2 ==
    [ pegOffset |-> [i \in 1 .. 8 |-> 0] ]

(* Peg Offset at zero, then each field in turn at the values it is checked at *)
CheckedPegOffset2 ==
    { ZeroPegOffset2 }
        \cup { [ZeroPegOffset2 EXCEPT !.pegOffset = one] : one \in Sample(8) }

(***************************************************************************)
(* Target Strategy: 2 bytes                                                *)
(***************************************************************************)

TargetStrategy2 ==
    [ targetStrategy : Sample(2) ]

EncodeTargetStrategy2(message) ==
    message.targetStrategy

DecodeTargetStrategy2(bytes) ==
    LET targetStrategy == ReadBytes(bytes, 2) IN IF ~targetStrategy.ok THEN Fail ELSE
    Ok([ targetStrategy |-> targetStrategy.value ], targetStrategy.rest)

ZeroTargetStrategy2 ==
    [ targetStrategy |-> [i \in 1 .. 2 |-> 0] ]

(* Target Strategy at zero, then each field in turn at the values it is checked at *)
CheckedTargetStrategy2 ==
    { ZeroTargetStrategy2 }
        \cup { [ZeroTargetStrategy2 EXCEPT !.targetStrategy = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Origination: 1 bytes                                              *)
(***************************************************************************)

OrderOrigination2 ==
    [ orderOrigination : Sample(1) ]

EncodeOrderOrigination2(message) ==
    message.orderOrigination

DecodeOrderOrigination2(bytes) ==
    LET orderOrigination == ReadBytes(bytes, 1) IN IF ~orderOrigination.ok THEN Fail ELSE
    Ok([ orderOrigination |-> orderOrigination.value ], orderOrigination.rest)

ZeroOrderOrigination2 ==
    [ orderOrigination |-> [i \in 1 .. 1 |-> 0] ]

(* Order Origination at zero, then each field in turn at the values it is checked at *)
CheckedOrderOrigination2 ==
    { ZeroOrderOrigination2 }
        \cup { [ZeroOrderOrigination2 EXCEPT !.orderOrigination = one] : one \in Sample(1) }

(***************************************************************************)
(* Routing Arrangement Indicator: 1 bytes                                  *)
(***************************************************************************)

RoutingArrangementIndicator2 ==
    [ routingArrangementIndicator : Sample(1) ]

EncodeRoutingArrangementIndicator2(message) ==
    message.routingArrangementIndicator

DecodeRoutingArrangementIndicator2(bytes) ==
    LET routingArrangementIndicator == ReadBytes(bytes, 1) IN IF ~routingArrangementIndicator.ok THEN Fail ELSE
    Ok([ routingArrangementIndicator |-> routingArrangementIndicator.value ], routingArrangementIndicator.rest)

ZeroRoutingArrangementIndicator2 ==
    [ routingArrangementIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Routing Arrangement Indicator at zero, then each field in turn at the values it is checked at *)
CheckedRoutingArrangementIndicator2 ==
    { ZeroRoutingArrangementIndicator2 }
        \cup { [ZeroRoutingArrangementIndicator2 EXCEPT !.routingArrangementIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Umir Regulation Id: 2 bytes                                             *)
(***************************************************************************)

UmirRegulationId2 ==
    [ umirRegulationId : Sample(2) ]

EncodeUmirRegulationId2(message) ==
    message.umirRegulationId

DecodeUmirRegulationId2(bytes) ==
    LET umirRegulationId == ReadBytes(bytes, 2) IN IF ~umirRegulationId.ok THEN Fail ELSE
    Ok([ umirRegulationId |-> umirRegulationId.value ], umirRegulationId.rest)

ZeroUmirRegulationId2 ==
    [ umirRegulationId |-> [i \in 1 .. 2 |-> 0] ]

(* Umir Regulation Id at zero, then each field in turn at the values it is checked at *)
CheckedUmirRegulationId2 ==
    { ZeroUmirRegulationId2 }
        \cup { [ZeroUmirRegulationId2 EXCEPT !.umirRegulationId = one] : one \in Sample(2) }

(***************************************************************************)
(* Anonymous: 1 bytes                                                      *)
(***************************************************************************)

Anonymous2 ==
    [ anonymous : Sample(1) ]

EncodeAnonymous2(message) ==
    message.anonymous

DecodeAnonymous2(bytes) ==
    LET anonymous == ReadBytes(bytes, 1) IN IF ~anonymous.ok THEN Fail ELSE
    Ok([ anonymous |-> anonymous.value ], anonymous.rest)

ZeroAnonymous2 ==
    [ anonymous |-> [i \in 1 .. 1 |-> 0] ]

(* Anonymous at zero, then each field in turn at the values it is checked at *)
CheckedAnonymous2 ==
    { ZeroAnonymous2 }
        \cup { [ZeroAnonymous2 EXCEPT !.anonymous = one] : one \in Sample(1) }

(***************************************************************************)
(* Display Range: 4 bytes                                                  *)
(***************************************************************************)

DisplayRange2 ==
    [ displayRange : Sample(4) ]

EncodeDisplayRange2(message) ==
    message.displayRange

DecodeDisplayRange2(bytes) ==
    LET displayRange == ReadBytes(bytes, 4) IN IF ~displayRange.ok THEN Fail ELSE
    Ok([ displayRange |-> displayRange.value ], displayRange.rest)

ZeroDisplayRange2 ==
    [ displayRange |-> [i \in 1 .. 4 |-> 0] ]

(* Display Range at zero, then each field in turn at the values it is checked at *)
CheckedDisplayRange2 ==
    { ZeroDisplayRange2 }
        \cup { [ZeroDisplayRange2 EXCEPT !.displayRange = one] : one \in Sample(4) }

(***************************************************************************)
(* Customer Account: 20 bytes                                              *)
(***************************************************************************)

CustomerAccount2 ==
    [ customerAccount : Sample(20) ]

EncodeCustomerAccount2(message) ==
    message.customerAccount

DecodeCustomerAccount2(bytes) ==
    LET customerAccount == ReadBytes(bytes, 20) IN IF ~customerAccount.ok THEN Fail ELSE
    Ok([ customerAccount |-> customerAccount.value ], customerAccount.rest)

ZeroCustomerAccount2 ==
    [ customerAccount |-> [i \in 1 .. 20 |-> 0] ]

(* Customer Account at zero, then each field in turn at the values it is checked at *)
CheckedCustomerAccount2 ==
    { ZeroCustomerAccount2 }
        \cup { [ZeroCustomerAccount2 EXCEPT !.customerAccount = one] : one \in Sample(20) }

(***************************************************************************)
(* Algorithm Id: 20 bytes                                                  *)
(***************************************************************************)

AlgorithmId2 ==
    [ algorithmId : Sample(20) ]

EncodeAlgorithmId2(message) ==
    message.algorithmId

DecodeAlgorithmId2(bytes) ==
    LET algorithmId == ReadBytes(bytes, 20) IN IF ~algorithmId.ok THEN Fail ELSE
    Ok([ algorithmId |-> algorithmId.value ], algorithmId.rest)

ZeroAlgorithmId2 ==
    [ algorithmId |-> [i \in 1 .. 20 |-> 0] ]

(* Algorithm Id at zero, then each field in turn at the values it is checked at *)
CheckedAlgorithmId2 ==
    { ZeroAlgorithmId2 }
        \cup { [ZeroAlgorithmId2 EXCEPT !.algorithmId = one] : one \in Sample(20) }

(***************************************************************************)
(* Customer Lei: 52 bytes                                                  *)
(***************************************************************************)

CustomerLei2 ==
    [ customerLei : Sample(52) ]

EncodeCustomerLei2(message) ==
    message.customerLei

DecodeCustomerLei2(bytes) ==
    LET customerLei == ReadBytes(bytes, 52) IN IF ~customerLei.ok THEN Fail ELSE
    Ok([ customerLei |-> customerLei.value ], customerLei.rest)

ZeroCustomerLei2 ==
    [ customerLei |-> [i \in 1 .. 52 |-> 0] ]

(* Customer Lei at zero, then each field in turn at the values it is checked at *)
CheckedCustomerLei2 ==
    { ZeroCustomerLei2 }
        \cup { [ZeroCustomerLei2 EXCEPT !.customerLei = one] : one \in Sample(52) }

(***************************************************************************)
(* Broker Lei: 20 bytes                                                    *)
(***************************************************************************)

BrokerLei2 ==
    [ brokerLei : Sample(20) ]

EncodeBrokerLei2(message) ==
    message.brokerLei

DecodeBrokerLei2(bytes) ==
    LET brokerLei == ReadBytes(bytes, 20) IN IF ~brokerLei.ok THEN Fail ELSE
    Ok([ brokerLei |-> brokerLei.value ], brokerLei.rest)

ZeroBrokerLei2 ==
    [ brokerLei |-> [i \in 1 .. 20 |-> 0] ]

(* Broker Lei at zero, then each field in turn at the values it is checked at *)
CheckedBrokerLei2 ==
    { ZeroBrokerLei2 }
        \cup { [ZeroBrokerLei2 EXCEPT !.brokerLei = one] : one \in Sample(20) }

(***************************************************************************)
(* Allow Conditional: 1 bytes                                              *)
(***************************************************************************)

AllowConditional2 ==
    [ allowConditional : Sample(1) ]

EncodeAllowConditional2(message) ==
    message.allowConditional

DecodeAllowConditional2(bytes) ==
    LET allowConditional == ReadBytes(bytes, 1) IN IF ~allowConditional.ok THEN Fail ELSE
    Ok([ allowConditional |-> allowConditional.value ], allowConditional.rest)

ZeroAllowConditional2 ==
    [ allowConditional |-> [i \in 1 .. 1 |-> 0] ]

(* Allow Conditional at zero, then each field in turn at the values it is checked at *)
CheckedAllowConditional2 ==
    { ZeroAllowConditional2 }
        \cup { [ZeroAllowConditional2 EXCEPT !.allowConditional = one] : one \in Sample(1) }

(***************************************************************************)
(* Cxd Connect: 1 bytes                                                    *)
(***************************************************************************)

CxdConnect2 ==
    [ cxdConnect : Sample(1) ]

EncodeCxdConnect2(message) ==
    message.cxdConnect

DecodeCxdConnect2(bytes) ==
    LET cxdConnect == ReadBytes(bytes, 1) IN IF ~cxdConnect.ok THEN Fail ELSE
    Ok([ cxdConnect |-> cxdConnect.value ], cxdConnect.rest)

ZeroCxdConnect2 ==
    [ cxdConnect |-> [i \in 1 .. 1 |-> 0] ]

(* Cxd Connect at zero, then each field in turn at the values it is checked at *)
CheckedCxdConnect2 ==
    { ZeroCxdConnect2 }
        \cup { [ZeroCxdConnect2 EXCEPT !.cxdConnect = one] : one \in Sample(1) }

(***************************************************************************)
(* Pure Stream Connect: 1 bytes                                            *)
(***************************************************************************)

PureStreamConnect2 ==
    [ pureStreamConnect : Sample(1) ]

EncodePureStreamConnect2(message) ==
    message.pureStreamConnect

DecodePureStreamConnect2(bytes) ==
    LET pureStreamConnect == ReadBytes(bytes, 1) IN IF ~pureStreamConnect.ok THEN Fail ELSE
    Ok([ pureStreamConnect |-> pureStreamConnect.value ], pureStreamConnect.rest)

ZeroPureStreamConnect2 ==
    [ pureStreamConnect |-> [i \in 1 .. 1 |-> 0] ]

(* Pure Stream Connect at zero, then each field in turn at the values it is checked at *)
CheckedPureStreamConnect2 ==
    { ZeroPureStreamConnect2 }
        \cup { [ZeroPureStreamConnect2 EXCEPT !.pureStreamConnect = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Rate: 2 bytes                                                       *)
(***************************************************************************)

MinRate2 ==
    [ minRate : Sample(2) ]

EncodeMinRate2(message) ==
    message.minRate

DecodeMinRate2(bytes) ==
    LET minRate == ReadBytes(bytes, 2) IN IF ~minRate.ok THEN Fail ELSE
    Ok([ minRate |-> minRate.value ], minRate.rest)

ZeroMinRate2 ==
    [ minRate |-> [i \in 1 .. 2 |-> 0] ]

(* Min Rate at zero, then each field in turn at the values it is checked at *)
CheckedMinRate2 ==
    { ZeroMinRate2 }
        \cup { [ZeroMinRate2 EXCEPT !.minRate = one] : one \in Sample(2) }

(***************************************************************************)
(* Max Rate: 2 bytes                                                       *)
(***************************************************************************)

MaxRate2 ==
    [ maxRate : Sample(2) ]

EncodeMaxRate2(message) ==
    message.maxRate

DecodeMaxRate2(bytes) ==
    LET maxRate == ReadBytes(bytes, 2) IN IF ~maxRate.ok THEN Fail ELSE
    Ok([ maxRate |-> maxRate.value ], maxRate.rest)

ZeroMaxRate2 ==
    [ maxRate |-> [i \in 1 .. 2 |-> 0] ]

(* Max Rate at zero, then each field in turn at the values it is checked at *)
CheckedMaxRate2 ==
    { ZeroMaxRate2 }
        \cup { [ZeroMaxRate2 EXCEPT !.maxRate = one] : one \in Sample(2) }

(***************************************************************************)
(* Handl Inst: 1 bytes                                                     *)
(***************************************************************************)

HandlInst2 ==
    [ handlInst : Sample(1) ]

EncodeHandlInst2(message) ==
    message.handlInst

DecodeHandlInst2(bytes) ==
    LET handlInst == ReadBytes(bytes, 1) IN IF ~handlInst.ok THEN Fail ELSE
    Ok([ handlInst |-> handlInst.value ], handlInst.rest)

ZeroHandlInst2 ==
    [ handlInst |-> [i \in 1 .. 1 |-> 0] ]

(* Handl Inst at zero, then each field in turn at the values it is checked at *)
CheckedHandlInst2 ==
    { ZeroHandlInst2 }
        \cup { [ZeroHandlInst2 EXCEPT !.handlInst = one] : one \in Sample(1) }

(***************************************************************************)
(* Reprice Reason: 1 bytes                                                 *)
(***************************************************************************)

RepriceReason2 ==
    [ repriceReason : Sample(1) ]

EncodeRepriceReason2(message) ==
    message.repriceReason

DecodeRepriceReason2(bytes) ==
    LET repriceReason == ReadBytes(bytes, 1) IN IF ~repriceReason.ok THEN Fail ELSE
    Ok([ repriceReason |-> repriceReason.value ], repriceReason.rest)

ZeroRepriceReason2 ==
    [ repriceReason |-> [i \in 1 .. 1 |-> 0] ]

(* Reprice Reason at zero, then each field in turn at the values it is checked at *)
CheckedRepriceReason2 ==
    { ZeroRepriceReason2 }
        \cup { [ZeroRepriceReason2 EXCEPT !.repriceReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Nbbo Setter: 1 bytes                                                    *)
(***************************************************************************)

NbboSetter2 ==
    [ nbboSetter : Sample(1) ]

EncodeNbboSetter2(message) ==
    message.nbboSetter

DecodeNbboSetter2(bytes) ==
    LET nbboSetter == ReadBytes(bytes, 1) IN IF ~nbboSetter.ok THEN Fail ELSE
    Ok([ nbboSetter |-> nbboSetter.value ], nbboSetter.rest)

ZeroNbboSetter2 ==
    [ nbboSetter |-> [i \in 1 .. 1 |-> 0] ]

(* Nbbo Setter at zero, then each field in turn at the values it is checked at *)
CheckedNbboSetter2 ==
    { ZeroNbboSetter2 }
        \cup { [ZeroNbboSetter2 EXCEPT !.nbboSetter = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Replaced Optional Value, selected by Order Replaced Optional      *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode2 == 37  \* 0x25
MinQtyTypeCode2 == 3  \* 0x03
PegTypeCode2 == 2  \* 0x02
MinQtyCode2 == 4  \* 0x04
MaxFloorCode2 == 5  \* 0x05
ExpireTimeCode2 == 6  \* 0x06
PegOffsetCode2 == 7  \* 0x07
TargetStrategyCode2 == 8  \* 0x08
OrderOriginationCode2 == 9  \* 0x09
RoutingArrangementIndicatorCode2 == 10  \* 0x0a
UmirRegulationIdCode2 == 17  \* 0x11
AnonymousCode2 == 16  \* 0x10
DisplayRangeCode2 == 24  \* 0x18
CustomerAccountCode2 == 25  \* 0x19
AlgorithmIdCode2 == 26  \* 0x1a
CustomerLeiCode2 == 27  \* 0x1b
BrokerLeiCode2 == 28  \* 0x1c
AllowConditionalCode2 == 30  \* 0x1e
CxdConnectCode2 == 32  \* 0x20
PureStreamConnectCode2 == 33  \* 0x21
MinRateCode2 == 34  \* 0x22
MaxRateCode2 == 35  \* 0x23
HandlInstCode2 == 43  \* 0x2b
RepriceReasonCode2 == 44  \* 0x2c
NbboSetterCode2 == 45  \* 0x2d

OrderReplacedOptionalValue ==
    [ tag : {UserRefIdxCode2}, body : UserRefIdx2 ]
        \cup [ tag : {MinQtyTypeCode2}, body : MinQtyType2 ]
        \cup [ tag : {PegTypeCode2}, body : PegType2 ]
        \cup [ tag : {MinQtyCode2}, body : MinQty2 ]
        \cup [ tag : {MaxFloorCode2}, body : MaxFloor2 ]
        \cup [ tag : {ExpireTimeCode2}, body : ExpireTime2 ]
        \cup [ tag : {PegOffsetCode2}, body : PegOffset2 ]
        \cup [ tag : {TargetStrategyCode2}, body : TargetStrategy2 ]
        \cup [ tag : {OrderOriginationCode2}, body : OrderOrigination2 ]
        \cup [ tag : {RoutingArrangementIndicatorCode2}, body : RoutingArrangementIndicator2 ]
        \cup [ tag : {UmirRegulationIdCode2}, body : UmirRegulationId2 ]
        \cup [ tag : {AnonymousCode2}, body : Anonymous2 ]
        \cup [ tag : {DisplayRangeCode2}, body : DisplayRange2 ]
        \cup [ tag : {CustomerAccountCode2}, body : CustomerAccount2 ]
        \cup [ tag : {AlgorithmIdCode2}, body : AlgorithmId2 ]
        \cup [ tag : {CustomerLeiCode2}, body : CustomerLei2 ]
        \cup [ tag : {BrokerLeiCode2}, body : BrokerLei2 ]
        \cup [ tag : {AllowConditionalCode2}, body : AllowConditional2 ]
        \cup [ tag : {CxdConnectCode2}, body : CxdConnect2 ]
        \cup [ tag : {PureStreamConnectCode2}, body : PureStreamConnect2 ]
        \cup [ tag : {MinRateCode2}, body : MinRate2 ]
        \cup [ tag : {MaxRateCode2}, body : MaxRate2 ]
        \cup [ tag : {HandlInstCode2}, body : HandlInst2 ]
        \cup [ tag : {RepriceReasonCode2}, body : RepriceReason2 ]
        \cup [ tag : {NbboSetterCode2}, body : NbboSetter2 ]

EncodeOrderReplacedOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode2 -> EncodeUserRefIdx2(message.body)
      [] message.tag = MinQtyTypeCode2 -> EncodeMinQtyType2(message.body)
      [] message.tag = PegTypeCode2 -> EncodePegType2(message.body)
      [] message.tag = MinQtyCode2 -> EncodeMinQty2(message.body)
      [] message.tag = MaxFloorCode2 -> EncodeMaxFloor2(message.body)
      [] message.tag = ExpireTimeCode2 -> EncodeExpireTime2(message.body)
      [] message.tag = PegOffsetCode2 -> EncodePegOffset2(message.body)
      [] message.tag = TargetStrategyCode2 -> EncodeTargetStrategy2(message.body)
      [] message.tag = OrderOriginationCode2 -> EncodeOrderOrigination2(message.body)
      [] message.tag = RoutingArrangementIndicatorCode2 -> EncodeRoutingArrangementIndicator2(message.body)
      [] message.tag = UmirRegulationIdCode2 -> EncodeUmirRegulationId2(message.body)
      [] message.tag = AnonymousCode2 -> EncodeAnonymous2(message.body)
      [] message.tag = DisplayRangeCode2 -> EncodeDisplayRange2(message.body)
      [] message.tag = CustomerAccountCode2 -> EncodeCustomerAccount2(message.body)
      [] message.tag = AlgorithmIdCode2 -> EncodeAlgorithmId2(message.body)
      [] message.tag = CustomerLeiCode2 -> EncodeCustomerLei2(message.body)
      [] message.tag = BrokerLeiCode2 -> EncodeBrokerLei2(message.body)
      [] message.tag = AllowConditionalCode2 -> EncodeAllowConditional2(message.body)
      [] message.tag = CxdConnectCode2 -> EncodeCxdConnect2(message.body)
      [] message.tag = PureStreamConnectCode2 -> EncodePureStreamConnect2(message.body)
      [] message.tag = MinRateCode2 -> EncodeMinRate2(message.body)
      [] message.tag = MaxRateCode2 -> EncodeMaxRate2(message.body)
      [] message.tag = HandlInstCode2 -> EncodeHandlInst2(message.body)
      [] message.tag = RepriceReasonCode2 -> EncodeRepriceReason2(message.body)
      [] message.tag = NbboSetterCode2 -> EncodeNbboSetter2(message.body)

DecodeOrderReplacedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode2 -> DecodeUserRefIdx2(bytes)
              [] tag = MinQtyTypeCode2 -> DecodeMinQtyType2(bytes)
              [] tag = PegTypeCode2 -> DecodePegType2(bytes)
              [] tag = MinQtyCode2 -> DecodeMinQty2(bytes)
              [] tag = MaxFloorCode2 -> DecodeMaxFloor2(bytes)
              [] tag = ExpireTimeCode2 -> DecodeExpireTime2(bytes)
              [] tag = PegOffsetCode2 -> DecodePegOffset2(bytes)
              [] tag = TargetStrategyCode2 -> DecodeTargetStrategy2(bytes)
              [] tag = OrderOriginationCode2 -> DecodeOrderOrigination2(bytes)
              [] tag = RoutingArrangementIndicatorCode2 -> DecodeRoutingArrangementIndicator2(bytes)
              [] tag = UmirRegulationIdCode2 -> DecodeUmirRegulationId2(bytes)
              [] tag = AnonymousCode2 -> DecodeAnonymous2(bytes)
              [] tag = DisplayRangeCode2 -> DecodeDisplayRange2(bytes)
              [] tag = CustomerAccountCode2 -> DecodeCustomerAccount2(bytes)
              [] tag = AlgorithmIdCode2 -> DecodeAlgorithmId2(bytes)
              [] tag = CustomerLeiCode2 -> DecodeCustomerLei2(bytes)
              [] tag = BrokerLeiCode2 -> DecodeBrokerLei2(bytes)
              [] tag = AllowConditionalCode2 -> DecodeAllowConditional2(bytes)
              [] tag = CxdConnectCode2 -> DecodeCxdConnect2(bytes)
              [] tag = PureStreamConnectCode2 -> DecodePureStreamConnect2(bytes)
              [] tag = MinRateCode2 -> DecodeMinRate2(bytes)
              [] tag = MaxRateCode2 -> DecodeMaxRate2(bytes)
              [] tag = HandlInstCode2 -> DecodeHandlInst2(bytes)
              [] tag = RepriceReasonCode2 -> DecodeRepriceReason2(bytes)
              [] tag = NbboSetterCode2 -> DecodeNbboSetter2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderReplacedOptionalValue == [tag |-> UserRefIdxCode2, body |-> ZeroUserRefIdx2]

(* Each Order Replaced Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderReplacedOptionalValue ==
    { [tag |-> UserRefIdxCode2, body |-> one] : one \in CheckedUserRefIdx2 }
        \cup { [tag |-> MinQtyTypeCode2, body |-> one] : one \in CheckedMinQtyType2 }
        \cup { [tag |-> PegTypeCode2, body |-> one] : one \in CheckedPegType2 }
        \cup { [tag |-> MinQtyCode2, body |-> one] : one \in CheckedMinQty2 }
        \cup { [tag |-> MaxFloorCode2, body |-> one] : one \in CheckedMaxFloor2 }
        \cup { [tag |-> ExpireTimeCode2, body |-> one] : one \in CheckedExpireTime2 }
        \cup { [tag |-> PegOffsetCode2, body |-> one] : one \in CheckedPegOffset2 }
        \cup { [tag |-> TargetStrategyCode2, body |-> one] : one \in CheckedTargetStrategy2 }
        \cup { [tag |-> OrderOriginationCode2, body |-> one] : one \in CheckedOrderOrigination2 }
        \cup { [tag |-> RoutingArrangementIndicatorCode2, body |-> one] : one \in CheckedRoutingArrangementIndicator2 }
        \cup { [tag |-> UmirRegulationIdCode2, body |-> one] : one \in CheckedUmirRegulationId2 }
        \cup { [tag |-> AnonymousCode2, body |-> one] : one \in CheckedAnonymous2 }
        \cup { [tag |-> DisplayRangeCode2, body |-> one] : one \in CheckedDisplayRange2 }
        \cup { [tag |-> CustomerAccountCode2, body |-> one] : one \in CheckedCustomerAccount2 }
        \cup { [tag |-> AlgorithmIdCode2, body |-> one] : one \in CheckedAlgorithmId2 }
        \cup { [tag |-> CustomerLeiCode2, body |-> one] : one \in CheckedCustomerLei2 }
        \cup { [tag |-> BrokerLeiCode2, body |-> one] : one \in CheckedBrokerLei2 }
        \cup { [tag |-> AllowConditionalCode2, body |-> one] : one \in CheckedAllowConditional2 }
        \cup { [tag |-> CxdConnectCode2, body |-> one] : one \in CheckedCxdConnect2 }
        \cup { [tag |-> PureStreamConnectCode2, body |-> one] : one \in CheckedPureStreamConnect2 }
        \cup { [tag |-> MinRateCode2, body |-> one] : one \in CheckedMinRate2 }
        \cup { [tag |-> MaxRateCode2, body |-> one] : one \in CheckedMaxRate2 }
        \cup { [tag |-> HandlInstCode2, body |-> one] : one \in CheckedHandlInst2 }
        \cup { [tag |-> RepriceReasonCode2, body |-> one] : one \in CheckedRepriceReason2 }
        \cup { [tag |-> NbboSetterCode2, body |-> one] : one \in CheckedNbboSetter2 }

(***************************************************************************)
(* Order Replaced Appendage, framed by Optional Field Length               *)
(***************************************************************************)

OrderReplacedAppendage ==
    [ orderReplacedOptionalValue : OrderReplacedOptionalValue ]

EncodeOrderReplacedAppendageBody(message) ==
    EncodeUIntBE(message.orderReplacedOptionalValue.tag, 1)
        \o EncodeOrderReplacedOptionalValue(message.orderReplacedOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeOrderReplacedAppendage(message) ==
    LET body == EncodeOrderReplacedAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeOrderReplacedAppendageBody(bytes) ==
    LET orderReplacedOptionalField == ReadUIntBE(bytes, 1) IN IF ~orderReplacedOptionalField.ok THEN Fail ELSE
    LET orderReplacedOptionalValue == DecodeOrderReplacedOptionalValue(orderReplacedOptionalField.value, orderReplacedOptionalField.rest) IN IF ~orderReplacedOptionalValue.ok THEN Fail ELSE
    Ok([ orderReplacedOptionalValue |-> orderReplacedOptionalValue.value ], orderReplacedOptionalValue.rest)

DecodeOrderReplacedAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeOrderReplacedAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroOrderReplacedAppendage ==
    [ orderReplacedOptionalValue |-> ZeroOrderReplacedOptionalValue ]

(* Order Replaced Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedAppendage ==
    { ZeroOrderReplacedAppendage }
        \cup { [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = one] : one \in CheckedOrderReplacedOptionalValue }

(* A run of Order Replaced Appendage, written one after another *)
RECURSIVE EncodeOrderReplacedAppendageList(_)
EncodeOrderReplacedAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderReplacedAppendage(Head(messages)) \o EncodeOrderReplacedAppendageList(Tail(messages))

(* As many Order Replaced Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadOrderReplacedAppendageAll(_)
ReadOrderReplacedAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeOrderReplacedAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderReplacedAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Replaced Appendage of each kind, for the lists that carry them *)
OneOrderReplacedAppendage ==
    { [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> UserRefIdxCode2, body |-> ZeroUserRefIdx2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> MinQtyTypeCode2, body |-> ZeroMinQtyType2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> PegTypeCode2, body |-> ZeroPegType2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> MinQtyCode2, body |-> ZeroMinQty2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> MaxFloorCode2, body |-> ZeroMaxFloor2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> ExpireTimeCode2, body |-> ZeroExpireTime2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> PegOffsetCode2, body |-> ZeroPegOffset2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> TargetStrategyCode2, body |-> ZeroTargetStrategy2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> OrderOriginationCode2, body |-> ZeroOrderOrigination2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> RoutingArrangementIndicatorCode2, body |-> ZeroRoutingArrangementIndicator2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> UmirRegulationIdCode2, body |-> ZeroUmirRegulationId2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> AnonymousCode2, body |-> ZeroAnonymous2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> DisplayRangeCode2, body |-> ZeroDisplayRange2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> CustomerAccountCode2, body |-> ZeroCustomerAccount2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> AlgorithmIdCode2, body |-> ZeroAlgorithmId2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> CustomerLeiCode2, body |-> ZeroCustomerLei2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> BrokerLeiCode2, body |-> ZeroBrokerLei2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> AllowConditionalCode2, body |-> ZeroAllowConditional2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> CxdConnectCode2, body |-> ZeroCxdConnect2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> PureStreamConnectCode2, body |-> ZeroPureStreamConnect2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> MinRateCode2, body |-> ZeroMinRate2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> MaxRateCode2, body |-> ZeroMaxRate2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> HandlInstCode2, body |-> ZeroHandlInst2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> RepriceReasonCode2, body |-> ZeroRepriceReason2]],
      [ZeroOrderReplacedAppendage EXCEPT !.orderReplacedOptionalValue = [tag |-> NbboSetterCode2, body |-> ZeroNbboSetter2]] }

(***************************************************************************)
(* Order Replaced Message                                                  *)
(***************************************************************************)

OrderReplacedMessage ==
    [ timestamp              : Sample(8),
      origUserRefNum         : Sample(4),
      userRefNum             : Sample(4),
      orderQty               : Sample(4),
      price                  : Sample(8),
      side                   : Sample(1),
      timeInForce            : Sample(1),
      orderReferenceNumber   : Sample(8),
      orderState             : Sample(1),
      orderReplacedAppendage : SampleLists(OneOrderReplacedAppendage) ]

EncodeOrderReplacedMessage(message) ==
    LET payload == EncodeOrderReplacedAppendageList(message.orderReplacedAppendage)
    IN  message.timestamp
            \o message.origUserRefNum
            \o message.userRefNum
            \o message.orderQty
            \o message.price
            \o message.side
            \o message.timeInForce
            \o message.orderReferenceNumber
            \o message.orderState
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderReplacedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET origUserRefNum == ReadBytes(timestamp.rest, 4) IN IF ~origUserRefNum.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(origUserRefNum.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET orderQty == ReadBytes(userRefNum.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timeInForce.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET orderState == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(orderState.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        orderReplacedAppendage == ReadOrderReplacedAppendageAll(framed)
    IN  IF ~orderReplacedAppendage.ok \/ orderReplacedAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         origUserRefNum         |-> origUserRefNum.value,
         userRefNum             |-> userRefNum.value,
         orderQty               |-> orderQty.value,
         price                  |-> price.value,
         side                   |-> side.value,
         timeInForce            |-> timeInForce.value,
         orderReferenceNumber   |-> orderReferenceNumber.value,
         orderState             |-> orderState.value,
         orderReplacedAppendage |-> orderReplacedAppendage.value ], beyond)

ZeroOrderReplacedMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      origUserRefNum         |-> [i \in 1 .. 4 |-> 0],
      userRefNum             |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      timeInForce            |-> [i \in 1 .. 1 |-> 0],
      orderReferenceNumber   |-> [i \in 1 .. 8 |-> 0],
      orderState             |-> [i \in 1 .. 1 |-> 0],
      orderReplacedAppendage |-> << >> ]

(* Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedMessage ==
    { ZeroOrderReplacedMessage }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.origUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderReplacedAppendage = one] : one \in SampleLists(OneOrderReplacedAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx3 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx3(message) ==
    message.userRefIdx

DecodeUserRefIdx3(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx3 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx3 ==
    { ZeroUserRefIdx3 }
        \cup { [ZeroUserRefIdx3 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Canceled Optional Value, selected by Order Canceled Optional      *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode3 == 37  \* 0x25

OrderCanceledOptionalValue ==
    [ tag : {UserRefIdxCode3}, body : UserRefIdx3 ]

EncodeOrderCanceledOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode3 -> EncodeUserRefIdx3(message.body)

DecodeOrderCanceledOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode3 -> DecodeUserRefIdx3(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderCanceledOptionalValue == [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]

(* Each Order Canceled Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderCanceledOptionalValue ==
    { [tag |-> UserRefIdxCode3, body |-> one] : one \in CheckedUserRefIdx3 }

(***************************************************************************)
(* Order Canceled Appendage, framed by Optional Field Length               *)
(***************************************************************************)

OrderCanceledAppendage ==
    [ orderCanceledOptionalValue : OrderCanceledOptionalValue ]

EncodeOrderCanceledAppendageBody(message) ==
    EncodeUIntBE(message.orderCanceledOptionalValue.tag, 1)
        \o EncodeOrderCanceledOptionalValue(message.orderCanceledOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeOrderCanceledAppendage(message) ==
    LET body == EncodeOrderCanceledAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeOrderCanceledAppendageBody(bytes) ==
    LET orderCanceledOptionalField == ReadUIntBE(bytes, 1) IN IF ~orderCanceledOptionalField.ok THEN Fail ELSE
    LET orderCanceledOptionalValue == DecodeOrderCanceledOptionalValue(orderCanceledOptionalField.value, orderCanceledOptionalField.rest) IN IF ~orderCanceledOptionalValue.ok THEN Fail ELSE
    Ok([ orderCanceledOptionalValue |-> orderCanceledOptionalValue.value ], orderCanceledOptionalValue.rest)

DecodeOrderCanceledAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeOrderCanceledAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroOrderCanceledAppendage ==
    [ orderCanceledOptionalValue |-> ZeroOrderCanceledOptionalValue ]

(* Order Canceled Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOrderCanceledAppendage ==
    { ZeroOrderCanceledAppendage }
        \cup { [ZeroOrderCanceledAppendage EXCEPT !.orderCanceledOptionalValue = one] : one \in CheckedOrderCanceledOptionalValue }

(* A run of Order Canceled Appendage, written one after another *)
RECURSIVE EncodeOrderCanceledAppendageList(_)
EncodeOrderCanceledAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderCanceledAppendage(Head(messages)) \o EncodeOrderCanceledAppendageList(Tail(messages))

(* As many Order Canceled Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadOrderCanceledAppendageAll(_)
ReadOrderCanceledAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeOrderCanceledAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderCanceledAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Canceled Appendage of each kind, for the lists that carry them *)
OneOrderCanceledAppendage ==
    { [ZeroOrderCanceledAppendage EXCEPT !.orderCanceledOptionalValue = [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]] }

(***************************************************************************)
(* Order Canceled Message                                                  *)
(***************************************************************************)

OrderCanceledMessage ==
    [ timestamp              : Sample(8),
      userRefNum             : Sample(4),
      orderQty               : Sample(4),
      cancelReason           : Sample(4),
      orderCanceledAppendage : SampleLists(OneOrderCanceledAppendage) ]

EncodeOrderCanceledMessage(message) ==
    LET payload == EncodeOrderCanceledAppendageList(message.orderCanceledAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.orderQty
            \o message.cancelReason
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET orderQty == ReadBytes(userRefNum.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(orderQty.rest, 4) IN IF ~cancelReason.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(cancelReason.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        orderCanceledAppendage == ReadOrderCanceledAppendageAll(framed)
    IN  IF ~orderCanceledAppendage.ok \/ orderCanceledAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         userRefNum             |-> userRefNum.value,
         orderQty               |-> orderQty.value,
         cancelReason           |-> cancelReason.value,
         orderCanceledAppendage |-> orderCanceledAppendage.value ], beyond)

ZeroOrderCanceledMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      userRefNum             |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      cancelReason           |-> [i \in 1 .. 4 |-> 0],
      orderCanceledAppendage |-> << >> ]

(* Order Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCanceledMessage ==
    { ZeroOrderCanceledMessage }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.cancelReason = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.orderCanceledAppendage = one] : one \in SampleLists(OneOrderCanceledAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx4 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx4(message) ==
    message.userRefIdx

DecodeUserRefIdx4(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx4 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx4 ==
    { ZeroUserRefIdx4 }
        \cup { [ZeroUserRefIdx4 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Stp Canceled Optional Value, selected by Stp Canceled Optional Field    *)
(***************************************************************************)

UserRefIdxCode4 == 37  \* 0x25

StpCanceledOptionalValue ==
    [ tag : {UserRefIdxCode4}, body : UserRefIdx4 ]

EncodeStpCanceledOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode4 -> EncodeUserRefIdx4(message.body)

DecodeStpCanceledOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode4 -> DecodeUserRefIdx4(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroStpCanceledOptionalValue == [tag |-> UserRefIdxCode4, body |-> ZeroUserRefIdx4]

(* Each Stp Canceled Optional Value in turn, at the values the message it names is checked at *)
CheckedStpCanceledOptionalValue ==
    { [tag |-> UserRefIdxCode4, body |-> one] : one \in CheckedUserRefIdx4 }

(***************************************************************************)
(* Stp Canceled Appendage, framed by Optional Field Length                 *)
(***************************************************************************)

StpCanceledAppendage ==
    [ stpCanceledOptionalValue : StpCanceledOptionalValue ]

EncodeStpCanceledAppendageBody(message) ==
    EncodeUIntBE(message.stpCanceledOptionalValue.tag, 1)
        \o EncodeStpCanceledOptionalValue(message.stpCanceledOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeStpCanceledAppendage(message) ==
    LET body == EncodeStpCanceledAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeStpCanceledAppendageBody(bytes) ==
    LET stpCanceledOptionalField == ReadUIntBE(bytes, 1) IN IF ~stpCanceledOptionalField.ok THEN Fail ELSE
    LET stpCanceledOptionalValue == DecodeStpCanceledOptionalValue(stpCanceledOptionalField.value, stpCanceledOptionalField.rest) IN IF ~stpCanceledOptionalValue.ok THEN Fail ELSE
    Ok([ stpCanceledOptionalValue |-> stpCanceledOptionalValue.value ], stpCanceledOptionalValue.rest)

DecodeStpCanceledAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeStpCanceledAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroStpCanceledAppendage ==
    [ stpCanceledOptionalValue |-> ZeroStpCanceledOptionalValue ]

(* Stp Canceled Appendage at zero, then each field in turn at the values it is checked at *)
CheckedStpCanceledAppendage ==
    { ZeroStpCanceledAppendage }
        \cup { [ZeroStpCanceledAppendage EXCEPT !.stpCanceledOptionalValue = one] : one \in CheckedStpCanceledOptionalValue }

(* A run of Stp Canceled Appendage, written one after another *)
RECURSIVE EncodeStpCanceledAppendageList(_)
EncodeStpCanceledAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStpCanceledAppendage(Head(messages)) \o EncodeStpCanceledAppendageList(Tail(messages))

(* As many Stp Canceled Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadStpCanceledAppendageAll(_)
ReadStpCanceledAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeStpCanceledAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStpCanceledAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Stp Canceled Appendage of each kind, for the lists that carry them *)
OneStpCanceledAppendage ==
    { [ZeroStpCanceledAppendage EXCEPT !.stpCanceledOptionalValue = [tag |-> UserRefIdxCode4, body |-> ZeroUserRefIdx4]] }

(***************************************************************************)
(* Stp Canceled Message                                                    *)
(***************************************************************************)

StpCanceledMessage ==
    [ timestamp                    : Sample(8),
      userRefNum                   : Sample(4),
      decrementShares              : Sample(4),
      cancelReason                 : Sample(4),
      quantityPreventedFromTrading : Sample(4),
      price                        : Sample(8),
      liquidityFlag                : Sample(1),
      stpCanceledAppendage         : SampleLists(OneStpCanceledAppendage) ]

EncodeStpCanceledMessage(message) ==
    LET payload == EncodeStpCanceledAppendageList(message.stpCanceledAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.decrementShares
            \o message.cancelReason
            \o message.quantityPreventedFromTrading
            \o message.price
            \o message.liquidityFlag
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeStpCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET decrementShares == ReadBytes(userRefNum.rest, 4) IN IF ~decrementShares.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(decrementShares.rest, 4) IN IF ~cancelReason.ok THEN Fail ELSE
    LET quantityPreventedFromTrading == ReadBytes(cancelReason.rest, 4) IN IF ~quantityPreventedFromTrading.ok THEN Fail ELSE
    LET price == ReadBytes(quantityPreventedFromTrading.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(price.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(liquidityFlag.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        stpCanceledAppendage == ReadStpCanceledAppendageAll(framed)
    IN  IF ~stpCanceledAppendage.ok \/ stpCanceledAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         userRefNum                   |-> userRefNum.value,
         decrementShares              |-> decrementShares.value,
         cancelReason                 |-> cancelReason.value,
         quantityPreventedFromTrading |-> quantityPreventedFromTrading.value,
         price                        |-> price.value,
         liquidityFlag                |-> liquidityFlag.value,
         stpCanceledAppendage         |-> stpCanceledAppendage.value ], beyond)

ZeroStpCanceledMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      userRefNum                   |-> [i \in 1 .. 4 |-> 0],
      decrementShares              |-> [i \in 1 .. 4 |-> 0],
      cancelReason                 |-> [i \in 1 .. 4 |-> 0],
      quantityPreventedFromTrading |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      liquidityFlag                |-> [i \in 1 .. 1 |-> 0],
      stpCanceledAppendage         |-> << >> ]

(* Stp Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedStpCanceledMessage ==
    { ZeroStpCanceledMessage }
        \cup { [ZeroStpCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStpCanceledMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroStpCanceledMessage EXCEPT !.decrementShares = one] : one \in Sample(4) }
        \cup { [ZeroStpCanceledMessage EXCEPT !.cancelReason = one] : one \in Sample(4) }
        \cup { [ZeroStpCanceledMessage EXCEPT !.quantityPreventedFromTrading = one] : one \in Sample(4) }
        \cup { [ZeroStpCanceledMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroStpCanceledMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroStpCanceledMessage EXCEPT !.stpCanceledAppendage = one] : one \in SampleLists(OneStpCanceledAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx5 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx5(message) ==
    message.userRefIdx

DecodeUserRefIdx5(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx5 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx5 ==
    { ZeroUserRefIdx5 }
        \cup { [ZeroUserRefIdx5 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Execute Match: 1 bytes                                                  *)
(***************************************************************************)

ExecuteMatch ==
    [ executeMatch : Sample(1) ]

EncodeExecuteMatch(message) ==
    message.executeMatch

DecodeExecuteMatch(bytes) ==
    LET executeMatch == ReadBytes(bytes, 1) IN IF ~executeMatch.ok THEN Fail ELSE
    Ok([ executeMatch |-> executeMatch.value ], executeMatch.rest)

ZeroExecuteMatch ==
    [ executeMatch |-> [i \in 1 .. 1 |-> 0] ]

(* Execute Match at zero, then each field in turn at the values it is checked at *)
CheckedExecuteMatch ==
    { ZeroExecuteMatch }
        \cup { [ZeroExecuteMatch EXCEPT !.executeMatch = one] : one \in Sample(1) }

(***************************************************************************)
(* Secondary Order Id: 8 bytes                                             *)
(***************************************************************************)

SecondaryOrderId ==
    [ secondaryOrderId : Sample(8) ]

EncodeSecondaryOrderId(message) ==
    message.secondaryOrderId

DecodeSecondaryOrderId(bytes) ==
    LET secondaryOrderId == ReadBytes(bytes, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    Ok([ secondaryOrderId |-> secondaryOrderId.value ], secondaryOrderId.rest)

ZeroSecondaryOrderId ==
    [ secondaryOrderId |-> [i \in 1 .. 8 |-> 0] ]

(* Secondary Order Id at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryOrderId ==
    { ZeroSecondaryOrderId }
        \cup { [ZeroSecondaryOrderId EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Broker Pref: 1 bytes                                                    *)
(***************************************************************************)

BrokerPref ==
    [ brokerPref : Sample(1) ]

EncodeBrokerPref(message) ==
    message.brokerPref

DecodeBrokerPref(bytes) ==
    LET brokerPref == ReadBytes(bytes, 1) IN IF ~brokerPref.ok THEN Fail ELSE
    Ok([ brokerPref |-> brokerPref.value ], brokerPref.rest)

ZeroBrokerPref ==
    [ brokerPref |-> [i \in 1 .. 1 |-> 0] ]

(* Broker Pref at zero, then each field in turn at the values it is checked at *)
CheckedBrokerPref ==
    { ZeroBrokerPref }
        \cup { [ZeroBrokerPref EXCEPT !.brokerPref = one] : one \in Sample(1) }

(***************************************************************************)
(* Principal Trade: 1 bytes                                                *)
(***************************************************************************)

PrincipalTrade ==
    [ principalTrade : Sample(1) ]

EncodePrincipalTrade(message) ==
    message.principalTrade

DecodePrincipalTrade(bytes) ==
    LET principalTrade == ReadBytes(bytes, 1) IN IF ~principalTrade.ok THEN Fail ELSE
    Ok([ principalTrade |-> principalTrade.value ], principalTrade.rest)

ZeroPrincipalTrade ==
    [ principalTrade |-> [i \in 1 .. 1 |-> 0] ]

(* Principal Trade at zero, then each field in turn at the values it is checked at *)
CheckedPrincipalTrade ==
    { ZeroPrincipalTrade }
        \cup { [ZeroPrincipalTrade EXCEPT !.principalTrade = one] : one \in Sample(1) }

(***************************************************************************)
(* Wash Trade: 1 bytes                                                     *)
(***************************************************************************)

WashTrade ==
    [ washTrade : Sample(1) ]

EncodeWashTrade(message) ==
    message.washTrade

DecodeWashTrade(bytes) ==
    LET washTrade == ReadBytes(bytes, 1) IN IF ~washTrade.ok THEN Fail ELSE
    Ok([ washTrade |-> washTrade.value ], washTrade.rest)

ZeroWashTrade ==
    [ washTrade |-> [i \in 1 .. 1 |-> 0] ]

(* Wash Trade at zero, then each field in turn at the values it is checked at *)
CheckedWashTrade ==
    { ZeroWashTrade }
        \cup { [ZeroWashTrade EXCEPT !.washTrade = one] : one \in Sample(1) }

(***************************************************************************)
(* Cum Rate: 2 bytes                                                       *)
(***************************************************************************)

CumRate ==
    [ cumRate : Sample(2) ]

EncodeCumRate(message) ==
    message.cumRate

DecodeCumRate(bytes) ==
    LET cumRate == ReadBytes(bytes, 2) IN IF ~cumRate.ok THEN Fail ELSE
    Ok([ cumRate |-> cumRate.value ], cumRate.rest)

ZeroCumRate ==
    [ cumRate |-> [i \in 1 .. 2 |-> 0] ]

(* Cum Rate at zero, then each field in turn at the values it is checked at *)
CheckedCumRate ==
    { ZeroCumRate }
        \cup { [ZeroCumRate EXCEPT !.cumRate = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Executed Optional Value, selected by Order Executed Optional      *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode5 == 37  \* 0x25
ExecuteMatchCode == 38  \* 0x26
SecondaryOrderIdCode == 40  \* 0x28
BrokerPrefCode == 42  \* 0x2a
PrincipalTradeCode == 13  \* 0x0d
WashTradeCode == 41  \* 0x29
CumRateCode == 36  \* 0x24

OrderExecutedOptionalValue ==
    [ tag : {UserRefIdxCode5}, body : UserRefIdx5 ]
        \cup [ tag : {ExecuteMatchCode}, body : ExecuteMatch ]
        \cup [ tag : {SecondaryOrderIdCode}, body : SecondaryOrderId ]
        \cup [ tag : {BrokerPrefCode}, body : BrokerPref ]
        \cup [ tag : {PrincipalTradeCode}, body : PrincipalTrade ]
        \cup [ tag : {WashTradeCode}, body : WashTrade ]
        \cup [ tag : {CumRateCode}, body : CumRate ]

EncodeOrderExecutedOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode5 -> EncodeUserRefIdx5(message.body)
      [] message.tag = ExecuteMatchCode -> EncodeExecuteMatch(message.body)
      [] message.tag = SecondaryOrderIdCode -> EncodeSecondaryOrderId(message.body)
      [] message.tag = BrokerPrefCode -> EncodeBrokerPref(message.body)
      [] message.tag = PrincipalTradeCode -> EncodePrincipalTrade(message.body)
      [] message.tag = WashTradeCode -> EncodeWashTrade(message.body)
      [] message.tag = CumRateCode -> EncodeCumRate(message.body)

DecodeOrderExecutedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode5 -> DecodeUserRefIdx5(bytes)
              [] tag = ExecuteMatchCode -> DecodeExecuteMatch(bytes)
              [] tag = SecondaryOrderIdCode -> DecodeSecondaryOrderId(bytes)
              [] tag = BrokerPrefCode -> DecodeBrokerPref(bytes)
              [] tag = PrincipalTradeCode -> DecodePrincipalTrade(bytes)
              [] tag = WashTradeCode -> DecodeWashTrade(bytes)
              [] tag = CumRateCode -> DecodeCumRate(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderExecutedOptionalValue == [tag |-> UserRefIdxCode5, body |-> ZeroUserRefIdx5]

(* Each Order Executed Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderExecutedOptionalValue ==
    { [tag |-> UserRefIdxCode5, body |-> one] : one \in CheckedUserRefIdx5 }
        \cup { [tag |-> ExecuteMatchCode, body |-> one] : one \in CheckedExecuteMatch }
        \cup { [tag |-> SecondaryOrderIdCode, body |-> one] : one \in CheckedSecondaryOrderId }
        \cup { [tag |-> BrokerPrefCode, body |-> one] : one \in CheckedBrokerPref }
        \cup { [tag |-> PrincipalTradeCode, body |-> one] : one \in CheckedPrincipalTrade }
        \cup { [tag |-> WashTradeCode, body |-> one] : one \in CheckedWashTrade }
        \cup { [tag |-> CumRateCode, body |-> one] : one \in CheckedCumRate }

(***************************************************************************)
(* Order Executed Appendage, framed by Optional Field Length               *)
(***************************************************************************)

OrderExecutedAppendage ==
    [ orderExecutedOptionalValue : OrderExecutedOptionalValue ]

EncodeOrderExecutedAppendageBody(message) ==
    EncodeUIntBE(message.orderExecutedOptionalValue.tag, 1)
        \o EncodeOrderExecutedOptionalValue(message.orderExecutedOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeOrderExecutedAppendage(message) ==
    LET body == EncodeOrderExecutedAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeOrderExecutedAppendageBody(bytes) ==
    LET orderExecutedOptionalField == ReadUIntBE(bytes, 1) IN IF ~orderExecutedOptionalField.ok THEN Fail ELSE
    LET orderExecutedOptionalValue == DecodeOrderExecutedOptionalValue(orderExecutedOptionalField.value, orderExecutedOptionalField.rest) IN IF ~orderExecutedOptionalValue.ok THEN Fail ELSE
    Ok([ orderExecutedOptionalValue |-> orderExecutedOptionalValue.value ], orderExecutedOptionalValue.rest)

DecodeOrderExecutedAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeOrderExecutedAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroOrderExecutedAppendage ==
    [ orderExecutedOptionalValue |-> ZeroOrderExecutedOptionalValue ]

(* Order Executed Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedAppendage ==
    { ZeroOrderExecutedAppendage }
        \cup { [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = one] : one \in CheckedOrderExecutedOptionalValue }

(* A run of Order Executed Appendage, written one after another *)
RECURSIVE EncodeOrderExecutedAppendageList(_)
EncodeOrderExecutedAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderExecutedAppendage(Head(messages)) \o EncodeOrderExecutedAppendageList(Tail(messages))

(* As many Order Executed Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadOrderExecutedAppendageAll(_)
ReadOrderExecutedAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeOrderExecutedAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderExecutedAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Executed Appendage of each kind, for the lists that carry them *)
OneOrderExecutedAppendage ==
    { [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> UserRefIdxCode5, body |-> ZeroUserRefIdx5]],
      [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> ExecuteMatchCode, body |-> ZeroExecuteMatch]],
      [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> SecondaryOrderIdCode, body |-> ZeroSecondaryOrderId]],
      [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> BrokerPrefCode, body |-> ZeroBrokerPref]],
      [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> PrincipalTradeCode, body |-> ZeroPrincipalTrade]],
      [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> WashTradeCode, body |-> ZeroWashTrade]],
      [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> CumRateCode, body |-> ZeroCumRate]] }

(***************************************************************************)
(* Order Executed Message                                                  *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp              : Sample(8),
      userRefNum             : Sample(4),
      quantity               : Sample(4),
      price                  : Sample(8),
      liquidityFlag          : Sample(1),
      matchNumber            : Sample(8),
      execBroker             : Sample(1),
      contraBroker           : Sample(4),
      orderExecutedAppendage : SampleLists(OneOrderExecutedAppendage) ]

EncodeOrderExecutedMessage(message) ==
    LET payload == EncodeOrderExecutedAppendageList(message.orderExecutedAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.quantity
            \o message.price
            \o message.liquidityFlag
            \o message.matchNumber
            \o message.execBroker
            \o message.contraBroker
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(userRefNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(price.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(liquidityFlag.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET execBroker == ReadBytes(matchNumber.rest, 1) IN IF ~execBroker.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(execBroker.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(contraBroker.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        orderExecutedAppendage == ReadOrderExecutedAppendageAll(framed)
    IN  IF ~orderExecutedAppendage.ok \/ orderExecutedAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         userRefNum             |-> userRefNum.value,
         quantity               |-> quantity.value,
         price                  |-> price.value,
         liquidityFlag          |-> liquidityFlag.value,
         matchNumber            |-> matchNumber.value,
         execBroker             |-> execBroker.value,
         contraBroker           |-> contraBroker.value,
         orderExecutedAppendage |-> orderExecutedAppendage.value ], beyond)

ZeroOrderExecutedMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      userRefNum             |-> [i \in 1 .. 4 |-> 0],
      quantity               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      liquidityFlag          |-> [i \in 1 .. 1 |-> 0],
      matchNumber            |-> [i \in 1 .. 8 |-> 0],
      execBroker             |-> [i \in 1 .. 1 |-> 0],
      contraBroker           |-> [i \in 1 .. 4 |-> 0],
      orderExecutedAppendage |-> << >> ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.execBroker = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.contraBroker = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderExecutedAppendage = one] : one \in SampleLists(OneOrderExecutedAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx6 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx6(message) ==
    message.userRefIdx

DecodeUserRefIdx6(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx6 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx6 ==
    { ZeroUserRefIdx6 }
        \cup { [ZeroUserRefIdx6 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Corrected Trade Optional Value, selected by Corrected Trade Optional    *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode6 == 37  \* 0x25

CorrectedTradeOptionalValue ==
    [ tag : {UserRefIdxCode6}, body : UserRefIdx6 ]

EncodeCorrectedTradeOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode6 -> EncodeUserRefIdx6(message.body)

DecodeCorrectedTradeOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode6 -> DecodeUserRefIdx6(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCorrectedTradeOptionalValue == [tag |-> UserRefIdxCode6, body |-> ZeroUserRefIdx6]

(* Each Corrected Trade Optional Value in turn, at the values the message it names is checked at *)
CheckedCorrectedTradeOptionalValue ==
    { [tag |-> UserRefIdxCode6, body |-> one] : one \in CheckedUserRefIdx6 }

(***************************************************************************)
(* Corrected Trade Appendage, framed by Optional Field Length              *)
(***************************************************************************)

CorrectedTradeAppendage ==
    [ correctedTradeOptionalValue : CorrectedTradeOptionalValue ]

EncodeCorrectedTradeAppendageBody(message) ==
    EncodeUIntBE(message.correctedTradeOptionalValue.tag, 1)
        \o EncodeCorrectedTradeOptionalValue(message.correctedTradeOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeCorrectedTradeAppendage(message) ==
    LET body == EncodeCorrectedTradeAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeCorrectedTradeAppendageBody(bytes) ==
    LET correctedTradeOptionalField == ReadUIntBE(bytes, 1) IN IF ~correctedTradeOptionalField.ok THEN Fail ELSE
    LET correctedTradeOptionalValue == DecodeCorrectedTradeOptionalValue(correctedTradeOptionalField.value, correctedTradeOptionalField.rest) IN IF ~correctedTradeOptionalValue.ok THEN Fail ELSE
    Ok([ correctedTradeOptionalValue |-> correctedTradeOptionalValue.value ], correctedTradeOptionalValue.rest)

DecodeCorrectedTradeAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeCorrectedTradeAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroCorrectedTradeAppendage ==
    [ correctedTradeOptionalValue |-> ZeroCorrectedTradeOptionalValue ]

(* Corrected Trade Appendage at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedTradeAppendage ==
    { ZeroCorrectedTradeAppendage }
        \cup { [ZeroCorrectedTradeAppendage EXCEPT !.correctedTradeOptionalValue = one] : one \in CheckedCorrectedTradeOptionalValue }

(* A run of Corrected Trade Appendage, written one after another *)
RECURSIVE EncodeCorrectedTradeAppendageList(_)
EncodeCorrectedTradeAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCorrectedTradeAppendage(Head(messages)) \o EncodeCorrectedTradeAppendageList(Tail(messages))

(* As many Corrected Trade Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadCorrectedTradeAppendageAll(_)
ReadCorrectedTradeAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeCorrectedTradeAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCorrectedTradeAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Corrected Trade Appendage of each kind, for the lists that carry them *)
OneCorrectedTradeAppendage ==
    { [ZeroCorrectedTradeAppendage EXCEPT !.correctedTradeOptionalValue = [tag |-> UserRefIdxCode6, body |-> ZeroUserRefIdx6]] }

(***************************************************************************)
(* Corrected Trade Message                                                 *)
(***************************************************************************)

CorrectedTradeMessage ==
    [ timestamp               : Sample(8),
      userRefNum              : Sample(4),
      matchNumber             : Sample(8),
      quantity                : Sample(4),
      price                   : Sample(8),
      correctedTradeAppendage : SampleLists(OneCorrectedTradeAppendage) ]

EncodeCorrectedTradeMessage(message) ==
    LET payload == EncodeCorrectedTradeAppendageList(message.correctedTradeAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.matchNumber
            \o message.quantity
            \o message.price
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeCorrectedTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(userRefNum.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(matchNumber.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(price.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        correctedTradeAppendage == ReadCorrectedTradeAppendageAll(framed)
    IN  IF ~correctedTradeAppendage.ok \/ correctedTradeAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         userRefNum              |-> userRefNum.value,
         matchNumber             |-> matchNumber.value,
         quantity                |-> quantity.value,
         price                   |-> price.value,
         correctedTradeAppendage |-> correctedTradeAppendage.value ], beyond)

ZeroCorrectedTradeMessage ==
    [ timestamp               |-> [i \in 1 .. 8 |-> 0],
      userRefNum              |-> [i \in 1 .. 4 |-> 0],
      matchNumber             |-> [i \in 1 .. 8 |-> 0],
      quantity                |-> [i \in 1 .. 4 |-> 0],
      price                   |-> [i \in 1 .. 8 |-> 0],
      correctedTradeAppendage |-> << >> ]

(* Corrected Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedTradeMessage ==
    { ZeroCorrectedTradeMessage }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.correctedTradeAppendage = one] : one \in SampleLists(OneCorrectedTradeAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx7 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx7(message) ==
    message.userRefIdx

DecodeUserRefIdx7(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx7 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx7 ==
    { ZeroUserRefIdx7 }
        \cup { [ZeroUserRefIdx7 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Rejected Order Optional Value, selected by Rejected Order Optional      *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode7 == 37  \* 0x25

RejectedOrderOptionalValue ==
    [ tag : {UserRefIdxCode7}, body : UserRefIdx7 ]

EncodeRejectedOrderOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode7 -> EncodeUserRefIdx7(message.body)

DecodeRejectedOrderOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode7 -> DecodeUserRefIdx7(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroRejectedOrderOptionalValue == [tag |-> UserRefIdxCode7, body |-> ZeroUserRefIdx7]

(* Each Rejected Order Optional Value in turn, at the values the message it names is checked at *)
CheckedRejectedOrderOptionalValue ==
    { [tag |-> UserRefIdxCode7, body |-> one] : one \in CheckedUserRefIdx7 }

(***************************************************************************)
(* Rejected Order Appendage, framed by Optional Field Length               *)
(***************************************************************************)

RejectedOrderAppendage ==
    [ rejectedOrderOptionalValue : RejectedOrderOptionalValue ]

EncodeRejectedOrderAppendageBody(message) ==
    EncodeUIntBE(message.rejectedOrderOptionalValue.tag, 1)
        \o EncodeRejectedOrderOptionalValue(message.rejectedOrderOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeRejectedOrderAppendage(message) ==
    LET body == EncodeRejectedOrderAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeRejectedOrderAppendageBody(bytes) ==
    LET rejectedOrderOptionalField == ReadUIntBE(bytes, 1) IN IF ~rejectedOrderOptionalField.ok THEN Fail ELSE
    LET rejectedOrderOptionalValue == DecodeRejectedOrderOptionalValue(rejectedOrderOptionalField.value, rejectedOrderOptionalField.rest) IN IF ~rejectedOrderOptionalValue.ok THEN Fail ELSE
    Ok([ rejectedOrderOptionalValue |-> rejectedOrderOptionalValue.value ], rejectedOrderOptionalValue.rest)

DecodeRejectedOrderAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeRejectedOrderAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroRejectedOrderAppendage ==
    [ rejectedOrderOptionalValue |-> ZeroRejectedOrderOptionalValue ]

(* Rejected Order Appendage at zero, then each field in turn at the values it is checked at *)
CheckedRejectedOrderAppendage ==
    { ZeroRejectedOrderAppendage }
        \cup { [ZeroRejectedOrderAppendage EXCEPT !.rejectedOrderOptionalValue = one] : one \in CheckedRejectedOrderOptionalValue }

(* A run of Rejected Order Appendage, written one after another *)
RECURSIVE EncodeRejectedOrderAppendageList(_)
EncodeRejectedOrderAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRejectedOrderAppendage(Head(messages)) \o EncodeRejectedOrderAppendageList(Tail(messages))

(* As many Rejected Order Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadRejectedOrderAppendageAll(_)
ReadRejectedOrderAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeRejectedOrderAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRejectedOrderAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Rejected Order Appendage of each kind, for the lists that carry them *)
OneRejectedOrderAppendage ==
    { [ZeroRejectedOrderAppendage EXCEPT !.rejectedOrderOptionalValue = [tag |-> UserRefIdxCode7, body |-> ZeroUserRefIdx7]] }

(***************************************************************************)
(* Rejected Order Message                                                  *)
(***************************************************************************)

RejectedOrderMessage ==
    [ timestamp              : Sample(8),
      userRefNum             : Sample(4),
      rejectReason           : Sample(4),
      rejectedOrderAppendage : SampleLists(OneRejectedOrderAppendage) ]

EncodeRejectedOrderMessage(message) ==
    LET payload == EncodeRejectedOrderAppendageList(message.rejectedOrderAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.rejectReason
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeRejectedOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(userRefNum.rest, 4) IN IF ~rejectReason.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(rejectReason.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        rejectedOrderAppendage == ReadRejectedOrderAppendageAll(framed)
    IN  IF ~rejectedOrderAppendage.ok \/ rejectedOrderAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         userRefNum             |-> userRefNum.value,
         rejectReason           |-> rejectReason.value,
         rejectedOrderAppendage |-> rejectedOrderAppendage.value ], beyond)

ZeroRejectedOrderMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      userRefNum             |-> [i \in 1 .. 4 |-> 0],
      rejectReason           |-> [i \in 1 .. 4 |-> 0],
      rejectedOrderAppendage |-> << >> ]

(* Rejected Order Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectedOrderMessage ==
    { ZeroRejectedOrderMessage }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.rejectReason = one] : one \in Sample(4) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.rejectedOrderAppendage = one] : one \in SampleLists(OneRejectedOrderAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx8 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx8(message) ==
    message.userRefIdx

DecodeUserRefIdx8(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx8 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx8 ==
    { ZeroUserRefIdx8 }
        \cup { [ZeroUserRefIdx8 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Reject Optional Value, selected by Cancel Reject Optional Field  *)
(***************************************************************************)

UserRefIdxCode8 == 37  \* 0x25

CancelRejectOptionalValue ==
    [ tag : {UserRefIdxCode8}, body : UserRefIdx8 ]

EncodeCancelRejectOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode8 -> EncodeUserRefIdx8(message.body)

DecodeCancelRejectOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode8 -> DecodeUserRefIdx8(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCancelRejectOptionalValue == [tag |-> UserRefIdxCode8, body |-> ZeroUserRefIdx8]

(* Each Cancel Reject Optional Value in turn, at the values the message it names is checked at *)
CheckedCancelRejectOptionalValue ==
    { [tag |-> UserRefIdxCode8, body |-> one] : one \in CheckedUserRefIdx8 }

(***************************************************************************)
(* Cancel Reject Appendage, framed by Optional Field Length                *)
(***************************************************************************)

CancelRejectAppendage ==
    [ cancelRejectOptionalValue : CancelRejectOptionalValue ]

EncodeCancelRejectAppendageBody(message) ==
    EncodeUIntBE(message.cancelRejectOptionalValue.tag, 1)
        \o EncodeCancelRejectOptionalValue(message.cancelRejectOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeCancelRejectAppendage(message) ==
    LET body == EncodeCancelRejectAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeCancelRejectAppendageBody(bytes) ==
    LET cancelRejectOptionalField == ReadUIntBE(bytes, 1) IN IF ~cancelRejectOptionalField.ok THEN Fail ELSE
    LET cancelRejectOptionalValue == DecodeCancelRejectOptionalValue(cancelRejectOptionalField.value, cancelRejectOptionalField.rest) IN IF ~cancelRejectOptionalValue.ok THEN Fail ELSE
    Ok([ cancelRejectOptionalValue |-> cancelRejectOptionalValue.value ], cancelRejectOptionalValue.rest)

DecodeCancelRejectAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeCancelRejectAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroCancelRejectAppendage ==
    [ cancelRejectOptionalValue |-> ZeroCancelRejectOptionalValue ]

(* Cancel Reject Appendage at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectAppendage ==
    { ZeroCancelRejectAppendage }
        \cup { [ZeroCancelRejectAppendage EXCEPT !.cancelRejectOptionalValue = one] : one \in CheckedCancelRejectOptionalValue }

(* A run of Cancel Reject Appendage, written one after another *)
RECURSIVE EncodeCancelRejectAppendageList(_)
EncodeCancelRejectAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCancelRejectAppendage(Head(messages)) \o EncodeCancelRejectAppendageList(Tail(messages))

(* As many Cancel Reject Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadCancelRejectAppendageAll(_)
ReadCancelRejectAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeCancelRejectAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCancelRejectAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cancel Reject Appendage of each kind, for the lists that carry them *)
OneCancelRejectAppendage ==
    { [ZeroCancelRejectAppendage EXCEPT !.cancelRejectOptionalValue = [tag |-> UserRefIdxCode8, body |-> ZeroUserRefIdx8]] }

(***************************************************************************)
(* Cancel Reject Message                                                   *)
(***************************************************************************)

CancelRejectMessage ==
    [ timestamp             : Sample(8),
      userRefNum            : Sample(4),
      rejectReason          : Sample(4),
      cancelRejectAppendage : SampleLists(OneCancelRejectAppendage) ]

EncodeCancelRejectMessage(message) ==
    LET payload == EncodeCancelRejectAppendageList(message.cancelRejectAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.rejectReason
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeCancelRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(userRefNum.rest, 4) IN IF ~rejectReason.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(rejectReason.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        cancelRejectAppendage == ReadCancelRejectAppendageAll(framed)
    IN  IF ~cancelRejectAppendage.ok \/ cancelRejectAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         userRefNum            |-> userRefNum.value,
         rejectReason          |-> rejectReason.value,
         cancelRejectAppendage |-> cancelRejectAppendage.value ], beyond)

ZeroCancelRejectMessage ==
    [ timestamp             |-> [i \in 1 .. 8 |-> 0],
      userRefNum            |-> [i \in 1 .. 4 |-> 0],
      rejectReason          |-> [i \in 1 .. 4 |-> 0],
      cancelRejectAppendage |-> << >> ]

(* Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectMessage ==
    { ZeroCancelRejectMessage }
        \cup { [ZeroCancelRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.rejectReason = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.cancelRejectAppendage = one] : one \in SampleLists(OneCancelRejectAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx9 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx9(message) ==
    message.userRefIdx

DecodeUserRefIdx9(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx9 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx9 ==
    { ZeroUserRefIdx9 }
        \cup { [ZeroUserRefIdx9 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Firm Up Id: 8 bytes                                                     *)
(***************************************************************************)

FirmUpId2 ==
    [ firmUpId : Sample(8) ]

EncodeFirmUpId2(message) ==
    message.firmUpId

DecodeFirmUpId2(bytes) ==
    LET firmUpId == ReadBytes(bytes, 8) IN IF ~firmUpId.ok THEN Fail ELSE
    Ok([ firmUpId |-> firmUpId.value ], firmUpId.rest)

ZeroFirmUpId2 ==
    [ firmUpId |-> [i \in 1 .. 8 |-> 0] ]

(* Firm Up Id at zero, then each field in turn at the values it is checked at *)
CheckedFirmUpId2 ==
    { ZeroFirmUpId2 }
        \cup { [ZeroFirmUpId2 EXCEPT !.firmUpId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Restated Optional Value, selected by Order Restated Optional      *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode9 == 37  \* 0x25
FirmUpIdCode2 == 31  \* 0x1f

OrderRestatedOptionalValue ==
    [ tag : {UserRefIdxCode9}, body : UserRefIdx9 ]
        \cup [ tag : {FirmUpIdCode2}, body : FirmUpId2 ]

EncodeOrderRestatedOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode9 -> EncodeUserRefIdx9(message.body)
      [] message.tag = FirmUpIdCode2 -> EncodeFirmUpId2(message.body)

DecodeOrderRestatedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode9 -> DecodeUserRefIdx9(bytes)
              [] tag = FirmUpIdCode2 -> DecodeFirmUpId2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderRestatedOptionalValue == [tag |-> UserRefIdxCode9, body |-> ZeroUserRefIdx9]

(* Each Order Restated Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderRestatedOptionalValue ==
    { [tag |-> UserRefIdxCode9, body |-> one] : one \in CheckedUserRefIdx9 }
        \cup { [tag |-> FirmUpIdCode2, body |-> one] : one \in CheckedFirmUpId2 }

(***************************************************************************)
(* Order Restated Appendage, framed by Optional Field Length               *)
(***************************************************************************)

OrderRestatedAppendage ==
    [ orderRestatedOptionalValue : OrderRestatedOptionalValue ]

EncodeOrderRestatedAppendageBody(message) ==
    EncodeUIntBE(message.orderRestatedOptionalValue.tag, 1)
        \o EncodeOrderRestatedOptionalValue(message.orderRestatedOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeOrderRestatedAppendage(message) ==
    LET body == EncodeOrderRestatedAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeOrderRestatedAppendageBody(bytes) ==
    LET orderRestatedOptionalField == ReadUIntBE(bytes, 1) IN IF ~orderRestatedOptionalField.ok THEN Fail ELSE
    LET orderRestatedOptionalValue == DecodeOrderRestatedOptionalValue(orderRestatedOptionalField.value, orderRestatedOptionalField.rest) IN IF ~orderRestatedOptionalValue.ok THEN Fail ELSE
    Ok([ orderRestatedOptionalValue |-> orderRestatedOptionalValue.value ], orderRestatedOptionalValue.rest)

DecodeOrderRestatedAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeOrderRestatedAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroOrderRestatedAppendage ==
    [ orderRestatedOptionalValue |-> ZeroOrderRestatedOptionalValue ]

(* Order Restated Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedAppendage ==
    { ZeroOrderRestatedAppendage }
        \cup { [ZeroOrderRestatedAppendage EXCEPT !.orderRestatedOptionalValue = one] : one \in CheckedOrderRestatedOptionalValue }

(* A run of Order Restated Appendage, written one after another *)
RECURSIVE EncodeOrderRestatedAppendageList(_)
EncodeOrderRestatedAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderRestatedAppendage(Head(messages)) \o EncodeOrderRestatedAppendageList(Tail(messages))

(* As many Order Restated Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadOrderRestatedAppendageAll(_)
ReadOrderRestatedAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeOrderRestatedAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderRestatedAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Restated Appendage of each kind, for the lists that carry them *)
OneOrderRestatedAppendage ==
    { [ZeroOrderRestatedAppendage EXCEPT !.orderRestatedOptionalValue = [tag |-> UserRefIdxCode9, body |-> ZeroUserRefIdx9]],
      [ZeroOrderRestatedAppendage EXCEPT !.orderRestatedOptionalValue = [tag |-> FirmUpIdCode2, body |-> ZeroFirmUpId2]] }

(***************************************************************************)
(* Order Restated Message                                                  *)
(***************************************************************************)

OrderRestatedMessage ==
    [ timestamp              : Sample(8),
      userRefNum             : Sample(4),
      restateReason          : Sample(1),
      orderRestatedAppendage : SampleLists(OneOrderRestatedAppendage) ]

EncodeOrderRestatedMessage(message) ==
    LET payload == EncodeOrderRestatedAppendageList(message.orderRestatedAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.restateReason
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderRestatedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET restateReason == ReadBytes(userRefNum.rest, 1) IN IF ~restateReason.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(restateReason.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        orderRestatedAppendage == ReadOrderRestatedAppendageAll(framed)
    IN  IF ~orderRestatedAppendage.ok \/ orderRestatedAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         userRefNum             |-> userRefNum.value,
         restateReason          |-> restateReason.value,
         orderRestatedAppendage |-> orderRestatedAppendage.value ], beyond)

ZeroOrderRestatedMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      userRefNum             |-> [i \in 1 .. 4 |-> 0],
      restateReason          |-> [i \in 1 .. 1 |-> 0],
      orderRestatedAppendage |-> << >> ]

(* Order Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedMessage ==
    { ZeroOrderRestatedMessage }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.restateReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.orderRestatedAppendage = one] : one \in SampleLists(OneOrderRestatedAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx10 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx10(message) ==
    message.userRefIdx

DecodeUserRefIdx10(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx10 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx10 ==
    { ZeroUserRefIdx10 }
        \cup { [ZeroUserRefIdx10 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Account Query Response Optional Value, selected by Account Query        *)
(* Response Optional Field                                                 *)
(***************************************************************************)

UserRefIdxCode10 == 37  \* 0x25

AccountQueryResponseOptionalValue ==
    [ tag : {UserRefIdxCode10}, body : UserRefIdx10 ]

EncodeAccountQueryResponseOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode10 -> EncodeUserRefIdx10(message.body)

DecodeAccountQueryResponseOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode10 -> DecodeUserRefIdx10(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAccountQueryResponseOptionalValue == [tag |-> UserRefIdxCode10, body |-> ZeroUserRefIdx10]

(* Each Account Query Response Optional Value in turn, at the values the message it names is checked at *)
CheckedAccountQueryResponseOptionalValue ==
    { [tag |-> UserRefIdxCode10, body |-> one] : one \in CheckedUserRefIdx10 }

(***************************************************************************)
(* Account Query Response Appendage, framed by Optional Field Length       *)
(***************************************************************************)

AccountQueryResponseAppendage ==
    [ accountQueryResponseOptionalValue : AccountQueryResponseOptionalValue ]

EncodeAccountQueryResponseAppendageBody(message) ==
    EncodeUIntBE(message.accountQueryResponseOptionalValue.tag, 1)
        \o EncodeAccountQueryResponseOptionalValue(message.accountQueryResponseOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeAccountQueryResponseAppendage(message) ==
    LET body == EncodeAccountQueryResponseAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeAccountQueryResponseAppendageBody(bytes) ==
    LET accountQueryResponseOptionalField == ReadUIntBE(bytes, 1) IN IF ~accountQueryResponseOptionalField.ok THEN Fail ELSE
    LET accountQueryResponseOptionalValue == DecodeAccountQueryResponseOptionalValue(accountQueryResponseOptionalField.value, accountQueryResponseOptionalField.rest) IN IF ~accountQueryResponseOptionalValue.ok THEN Fail ELSE
    Ok([ accountQueryResponseOptionalValue |-> accountQueryResponseOptionalValue.value ], accountQueryResponseOptionalValue.rest)

DecodeAccountQueryResponseAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeAccountQueryResponseAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroAccountQueryResponseAppendage ==
    [ accountQueryResponseOptionalValue |-> ZeroAccountQueryResponseOptionalValue ]

(* Account Query Response Appendage at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryResponseAppendage ==
    { ZeroAccountQueryResponseAppendage }
        \cup { [ZeroAccountQueryResponseAppendage EXCEPT !.accountQueryResponseOptionalValue = one] : one \in CheckedAccountQueryResponseOptionalValue }

(* A run of Account Query Response Appendage, written one after another *)
RECURSIVE EncodeAccountQueryResponseAppendageList(_)
EncodeAccountQueryResponseAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAccountQueryResponseAppendage(Head(messages)) \o EncodeAccountQueryResponseAppendageList(Tail(messages))

(* As many Account Query Response Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadAccountQueryResponseAppendageAll(_)
ReadAccountQueryResponseAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeAccountQueryResponseAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAccountQueryResponseAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Account Query Response Appendage of each kind, for the lists that carry them *)
OneAccountQueryResponseAppendage ==
    { [ZeroAccountQueryResponseAppendage EXCEPT !.accountQueryResponseOptionalValue = [tag |-> UserRefIdxCode10, body |-> ZeroUserRefIdx10]] }

(***************************************************************************)
(* Account Query Response Message                                          *)
(***************************************************************************)

AccountQueryResponseMessageTail ==
    [ accountQueryResponseAppendage : SampleLists(OneAccountQueryResponseAppendage) ]

EncodeAccountQueryResponseMessageTail(message) ==
    LET payload == EncodeAccountQueryResponseAppendageList(message.accountQueryResponseAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeAccountQueryResponseMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        accountQueryResponseAppendage == ReadAccountQueryResponseAppendageAll(framed)
    IN  IF ~accountQueryResponseAppendage.ok \/ accountQueryResponseAppendage.rest # << >> THEN Fail ELSE
    Ok([ accountQueryResponseAppendage |-> accountQueryResponseAppendage.value ], beyond)

ZeroAccountQueryResponseMessageTail ==
    [ accountQueryResponseAppendage |-> << >> ]

(* Account Query Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryResponseMessageTail ==
    { ZeroAccountQueryResponseMessageTail }
        \cup { [ZeroAccountQueryResponseMessageTail EXCEPT !.accountQueryResponseAppendage = one] : one \in SampleLists(OneAccountQueryResponseAppendage) }

(* Account Query Response Message runs on only when bytes remain, so it is there or it is not *)
WithoutAccountQueryResponseMessageTail == [there |-> FALSE, value |-> ZeroAccountQueryResponseMessageTail]

MaybeAccountQueryResponseMessageTail ==
    { WithoutAccountQueryResponseMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedAccountQueryResponseMessageTail }

ReadAccountQueryResponseMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutAccountQueryResponseMessageTail, << >>)
    ELSE LET one == DecodeAccountQueryResponseMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Account Query Response Message                                          *)
(***************************************************************************)

AccountQueryResponseMessage ==
    [ timestamp                       : Sample(8),
      nextUserRefNum                  : Sample(4),
      accountQueryResponseMessageTail : MaybeAccountQueryResponseMessageTail ]

EncodeAccountQueryResponseMessage(message) ==
    message.timestamp
        \o message.nextUserRefNum
        \o IF message.accountQueryResponseMessageTail.there THEN EncodeAccountQueryResponseMessageTail(message.accountQueryResponseMessageTail.value) ELSE << >>

DecodeAccountQueryResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET nextUserRefNum == ReadBytes(timestamp.rest, 4) IN IF ~nextUserRefNum.ok THEN Fail ELSE
    LET accountQueryResponseMessageTail == ReadAccountQueryResponseMessageTailMaybe(nextUserRefNum.rest) IN IF ~accountQueryResponseMessageTail.ok THEN Fail ELSE
    Ok([ timestamp                       |-> timestamp.value,
         nextUserRefNum                  |-> nextUserRefNum.value,
         accountQueryResponseMessageTail |-> accountQueryResponseMessageTail.value ], accountQueryResponseMessageTail.rest)

ZeroAccountQueryResponseMessage ==
    [ timestamp                       |-> [i \in 1 .. 8 |-> 0],
      nextUserRefNum                  |-> [i \in 1 .. 4 |-> 0],
      accountQueryResponseMessageTail |-> WithoutAccountQueryResponseMessageTail ]

(* Account Query Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryResponseMessage ==
    { ZeroAccountQueryResponseMessage }
        \cup { [ZeroAccountQueryResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAccountQueryResponseMessage EXCEPT !.nextUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroAccountQueryResponseMessage EXCEPT !.accountQueryResponseMessageTail = one] : one \in MaybeAccountQueryResponseMessageTail }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OrderAcceptedMessageCode == 65  \* "A"
OrderReplacedMessageCode == 85  \* "U"
OrderCanceledMessageCode == 67  \* "C"
StpCanceledMessageCode == 68  \* "D"
OrderExecutedMessageCode == 69  \* "E"
CorrectedTradeMessageCode == 66  \* "B"
RejectedOrderMessageCode == 74  \* "J"
CancelRejectMessageCode == 73  \* "I"
OrderRestatedMessageCode == 82  \* "R"
AccountQueryResponseMessageCode == 81  \* "Q"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderAcceptedMessageCode}, body : OrderAcceptedMessage ]
        \cup [ tag : {OrderReplacedMessageCode}, body : OrderReplacedMessage ]
        \cup [ tag : {OrderCanceledMessageCode}, body : OrderCanceledMessage ]
        \cup [ tag : {StpCanceledMessageCode}, body : StpCanceledMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {CorrectedTradeMessageCode}, body : CorrectedTradeMessage ]
        \cup [ tag : {RejectedOrderMessageCode}, body : RejectedOrderMessage ]
        \cup [ tag : {CancelRejectMessageCode}, body : CancelRejectMessage ]
        \cup [ tag : {OrderRestatedMessageCode}, body : OrderRestatedMessage ]
        \cup [ tag : {AccountQueryResponseMessageCode}, body : AccountQueryResponseMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderAcceptedMessageCode -> EncodeOrderAcceptedMessage(message.body)
      [] message.tag = OrderReplacedMessageCode -> EncodeOrderReplacedMessage(message.body)
      [] message.tag = OrderCanceledMessageCode -> EncodeOrderCanceledMessage(message.body)
      [] message.tag = StpCanceledMessageCode -> EncodeStpCanceledMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = CorrectedTradeMessageCode -> EncodeCorrectedTradeMessage(message.body)
      [] message.tag = RejectedOrderMessageCode -> EncodeRejectedOrderMessage(message.body)
      [] message.tag = CancelRejectMessageCode -> EncodeCancelRejectMessage(message.body)
      [] message.tag = OrderRestatedMessageCode -> EncodeOrderRestatedMessage(message.body)
      [] message.tag = AccountQueryResponseMessageCode -> EncodeAccountQueryResponseMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderAcceptedMessageCode -> DecodeOrderAcceptedMessage(bytes)
              [] tag = OrderReplacedMessageCode -> DecodeOrderReplacedMessage(bytes)
              [] tag = OrderCanceledMessageCode -> DecodeOrderCanceledMessage(bytes)
              [] tag = StpCanceledMessageCode -> DecodeStpCanceledMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = CorrectedTradeMessageCode -> DecodeCorrectedTradeMessage(bytes)
              [] tag = RejectedOrderMessageCode -> DecodeRejectedOrderMessage(bytes)
              [] tag = CancelRejectMessageCode -> DecodeCancelRejectMessage(bytes)
              [] tag = OrderRestatedMessageCode -> DecodeOrderRestatedMessage(bytes)
              [] tag = AccountQueryResponseMessageCode -> DecodeAccountQueryResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderAcceptedMessageCode, body |-> one] : one \in CheckedOrderAcceptedMessage }
        \cup { [tag |-> OrderReplacedMessageCode, body |-> one] : one \in CheckedOrderReplacedMessage }
        \cup { [tag |-> OrderCanceledMessageCode, body |-> one] : one \in CheckedOrderCanceledMessage }
        \cup { [tag |-> StpCanceledMessageCode, body |-> one] : one \in CheckedStpCanceledMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> CorrectedTradeMessageCode, body |-> one] : one \in CheckedCorrectedTradeMessage }
        \cup { [tag |-> RejectedOrderMessageCode, body |-> one] : one \in CheckedRejectedOrderMessage }
        \cup { [tag |-> CancelRejectMessageCode, body |-> one] : one \in CheckedCancelRejectMessage }
        \cup { [tag |-> OrderRestatedMessageCode, body |-> one] : one \in CheckedOrderRestatedMessage }
        \cup { [tag |-> AccountQueryResponseMessageCode, body |-> one] : one \in CheckedAccountQueryResponseMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx ==
    \A message \in CheckedUserRefIdx :
        LET read == DecodeUserRefIdx(EncodeUserRefIdx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account decodes back to what was encoded, and leaves nothing over *)
RoundTripAccount ==
    \A message \in CheckedAccount :
        LET read == DecodeAccount(EncodeAccount(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPegType ==
    \A message \in CheckedPegType :
        LET read == DecodePegType(EncodePegType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Qty Type decodes back to what was encoded, and leaves nothing over *)
RoundTripMinQtyType ==
    \A message \in CheckedMinQtyType :
        LET read == DecodeMinQtyType(EncodeMinQtyType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripMinQty ==
    \A message \in CheckedMinQty :
        LET read == DecodeMinQty(EncodeMinQty(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Floor decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxFloor ==
    \A message \in CheckedMaxFloor :
        LET read == DecodeMaxFloor(EncodeMaxFloor(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expire Time decodes back to what was encoded, and leaves nothing over *)
RoundTripExpireTime ==
    \A message \in CheckedExpireTime :
        LET read == DecodeExpireTime(EncodeExpireTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Offset decodes back to what was encoded, and leaves nothing over *)
RoundTripPegOffset ==
    \A message \in CheckedPegOffset :
        LET read == DecodePegOffset(EncodePegOffset(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Target Strategy decodes back to what was encoded, and leaves nothing over *)
RoundTripTargetStrategy ==
    \A message \in CheckedTargetStrategy :
        LET read == DecodeTargetStrategy(EncodeTargetStrategy(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Origination decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderOrigination ==
    \A message \in CheckedOrderOrigination :
        LET read == DecodeOrderOrigination(EncodeOrderOrigination(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Routing Arrangement Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripRoutingArrangementIndicator ==
    \A message \in CheckedRoutingArrangementIndicator :
        LET read == DecodeRoutingArrangementIndicator(EncodeRoutingArrangementIndicator(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Basket Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripBasketTrade ==
    \A message \in CheckedBasketTrade :
        LET read == DecodeBasketTrade(EncodeBasketTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Program Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripProgramTrade ==
    \A message \in CheckedProgramTrade :
        LET read == DecodeProgramTrade(EncodeProgramTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Jitney decodes back to what was encoded, and leaves nothing over *)
RoundTripJitney ==
    \A message \in CheckedJitney :
        LET read == DecodeJitney(EncodeJitney(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gef Eligible decodes back to what was encoded, and leaves nothing over *)
RoundTripGefEligible ==
    \A message \in CheckedGefEligible :
        LET read == DecodeGefEligible(EncodeGefEligible(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Anonymous decodes back to what was encoded, and leaves nothing over *)
RoundTripAnonymous ==
    \A message \in CheckedAnonymous :
        LET read == DecodeAnonymous(EncodeAnonymous(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Umir Regulation Id decodes back to what was encoded, and leaves nothing over *)
RoundTripUmirRegulationId ==
    \A message \in CheckedUmirRegulationId :
        LET read == DecodeUmirRegulationId(EncodeUmirRegulationId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bypass decodes back to what was encoded, and leaves nothing over *)
RoundTripBypass ==
    \A message \in CheckedBypass :
        LET read == DecodeBypass(EncodeBypass(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tsxncib decodes back to what was encoded, and leaves nothing over *)
RoundTripTsxncib ==
    \A message \in CheckedTsxncib :
        LET read == DecodeTsxncib(EncodeTsxncib(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every No Trade Feat decodes back to what was encoded, and leaves nothing over *)
RoundTripNoTradeFeat ==
    \A message \in CheckedNoTradeFeat :
        LET read == DecodeNoTradeFeat(EncodeNoTradeFeat(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every No Trade Key decodes back to what was encoded, and leaves nothing over *)
RoundTripNoTradeKey ==
    \A message \in CheckedNoTradeKey :
        LET read == DecodeNoTradeKey(EncodeNoTradeKey(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Marking Exempt decodes back to what was encoded, and leaves nothing over *)
RoundTripShortMarkingExempt ==
    \A message \in CheckedShortMarkingExempt :
        LET read == DecodeShortMarkingExempt(EncodeShortMarkingExempt(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Po Comment decodes back to what was encoded, and leaves nothing over *)
RoundTripPoComment ==
    \A message \in CheckedPoComment :
        LET read == DecodePoComment(EncodePoComment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Range decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayRange ==
    \A message \in CheckedDisplayRange :
        LET read == DecodeDisplayRange(EncodeDisplayRange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Customer Account decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomerAccount ==
    \A message \in CheckedCustomerAccount :
        LET read == DecodeCustomerAccount(EncodeCustomerAccount(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Algorithm Id decodes back to what was encoded, and leaves nothing over *)
RoundTripAlgorithmId ==
    \A message \in CheckedAlgorithmId :
        LET read == DecodeAlgorithmId(EncodeAlgorithmId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Customer Lei decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomerLei ==
    \A message \in CheckedCustomerLei :
        LET read == DecodeCustomerLei(EncodeCustomerLei(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broker Lei decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokerLei ==
    \A message \in CheckedBrokerLei :
        LET read == DecodeBrokerLei(EncodeBrokerLei(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Conditional Order decodes back to what was encoded, and leaves nothing over *)
RoundTripConditionalOrder ==
    \A message \in CheckedConditionalOrder :
        LET read == DecodeConditionalOrder(EncodeConditionalOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allow Conditional decodes back to what was encoded, and leaves nothing over *)
RoundTripAllowConditional ==
    \A message \in CheckedAllowConditional :
        LET read == DecodeAllowConditional(EncodeAllowConditional(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Up Id decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmUpId ==
    \A message \in CheckedFirmUpId :
        LET read == DecodeFirmUpId(EncodeFirmUpId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cxd Connect decodes back to what was encoded, and leaves nothing over *)
RoundTripCxdConnect ==
    \A message \in CheckedCxdConnect :
        LET read == DecodeCxdConnect(EncodeCxdConnect(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pure Stream Connect decodes back to what was encoded, and leaves nothing over *)
RoundTripPureStreamConnect ==
    \A message \in CheckedPureStreamConnect :
        LET read == DecodePureStreamConnect(EncodePureStreamConnect(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMinRate ==
    \A message \in CheckedMinRate :
        LET read == DecodeMinRate(EncodeMinRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxRate ==
    \A message \in CheckedMaxRate :
        LET read == DecodeMaxRate(EncodeMaxRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Routing Strategy decodes back to what was encoded, and leaves nothing over *)
RoundTripRoutingStrategy ==
    \A message \in CheckedRoutingStrategy :
        LET read == DecodeRoutingStrategy(EncodeRoutingStrategy(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Handl Inst decodes back to what was encoded, and leaves nothing over *)
RoundTripHandlInst ==
    \A message \in CheckedHandlInst :
        LET read == DecodeHandlInst(EncodeHandlInst(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reprice Reason decodes back to what was encoded, and leaves nothing over *)
RoundTripRepriceReason ==
    \A message \in CheckedRepriceReason :
        LET read == DecodeRepriceReason(EncodeRepriceReason(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nbbo Setter decodes back to what was encoded, and leaves nothing over *)
RoundTripNbboSetter ==
    \A message \in CheckedNbboSetter :
        LET read == DecodeNbboSetter(EncodeNbboSetter(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Accepted Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcceptedAppendage ==
    \A message \in CheckedOrderAcceptedAppendage :
        LET read == DecodeOrderAcceptedAppendage(EncodeOrderAcceptedAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcceptedMessage ==
    \A message \in CheckedOrderAcceptedMessage :
        LET read == DecodeOrderAcceptedMessage(EncodeOrderAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx2 ==
    \A message \in CheckedUserRefIdx2 :
        LET read == DecodeUserRefIdx2(EncodeUserRefIdx2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Qty Type decodes back to what was encoded, and leaves nothing over *)
RoundTripMinQtyType2 ==
    \A message \in CheckedMinQtyType2 :
        LET read == DecodeMinQtyType2(EncodeMinQtyType2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPegType2 ==
    \A message \in CheckedPegType2 :
        LET read == DecodePegType2(EncodePegType2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Qty decodes back to what was encoded, and leaves nothing over *)
RoundTripMinQty2 ==
    \A message \in CheckedMinQty2 :
        LET read == DecodeMinQty2(EncodeMinQty2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Floor decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxFloor2 ==
    \A message \in CheckedMaxFloor2 :
        LET read == DecodeMaxFloor2(EncodeMaxFloor2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expire Time decodes back to what was encoded, and leaves nothing over *)
RoundTripExpireTime2 ==
    \A message \in CheckedExpireTime2 :
        LET read == DecodeExpireTime2(EncodeExpireTime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Offset decodes back to what was encoded, and leaves nothing over *)
RoundTripPegOffset2 ==
    \A message \in CheckedPegOffset2 :
        LET read == DecodePegOffset2(EncodePegOffset2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Target Strategy decodes back to what was encoded, and leaves nothing over *)
RoundTripTargetStrategy2 ==
    \A message \in CheckedTargetStrategy2 :
        LET read == DecodeTargetStrategy2(EncodeTargetStrategy2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Origination decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderOrigination2 ==
    \A message \in CheckedOrderOrigination2 :
        LET read == DecodeOrderOrigination2(EncodeOrderOrigination2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Routing Arrangement Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripRoutingArrangementIndicator2 ==
    \A message \in CheckedRoutingArrangementIndicator2 :
        LET read == DecodeRoutingArrangementIndicator2(EncodeRoutingArrangementIndicator2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Umir Regulation Id decodes back to what was encoded, and leaves nothing over *)
RoundTripUmirRegulationId2 ==
    \A message \in CheckedUmirRegulationId2 :
        LET read == DecodeUmirRegulationId2(EncodeUmirRegulationId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Anonymous decodes back to what was encoded, and leaves nothing over *)
RoundTripAnonymous2 ==
    \A message \in CheckedAnonymous2 :
        LET read == DecodeAnonymous2(EncodeAnonymous2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Range decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayRange2 ==
    \A message \in CheckedDisplayRange2 :
        LET read == DecodeDisplayRange2(EncodeDisplayRange2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Customer Account decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomerAccount2 ==
    \A message \in CheckedCustomerAccount2 :
        LET read == DecodeCustomerAccount2(EncodeCustomerAccount2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Algorithm Id decodes back to what was encoded, and leaves nothing over *)
RoundTripAlgorithmId2 ==
    \A message \in CheckedAlgorithmId2 :
        LET read == DecodeAlgorithmId2(EncodeAlgorithmId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Customer Lei decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomerLei2 ==
    \A message \in CheckedCustomerLei2 :
        LET read == DecodeCustomerLei2(EncodeCustomerLei2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broker Lei decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokerLei2 ==
    \A message \in CheckedBrokerLei2 :
        LET read == DecodeBrokerLei2(EncodeBrokerLei2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allow Conditional decodes back to what was encoded, and leaves nothing over *)
RoundTripAllowConditional2 ==
    \A message \in CheckedAllowConditional2 :
        LET read == DecodeAllowConditional2(EncodeAllowConditional2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cxd Connect decodes back to what was encoded, and leaves nothing over *)
RoundTripCxdConnect2 ==
    \A message \in CheckedCxdConnect2 :
        LET read == DecodeCxdConnect2(EncodeCxdConnect2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pure Stream Connect decodes back to what was encoded, and leaves nothing over *)
RoundTripPureStreamConnect2 ==
    \A message \in CheckedPureStreamConnect2 :
        LET read == DecodePureStreamConnect2(EncodePureStreamConnect2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMinRate2 ==
    \A message \in CheckedMinRate2 :
        LET read == DecodeMinRate2(EncodeMinRate2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxRate2 ==
    \A message \in CheckedMaxRate2 :
        LET read == DecodeMaxRate2(EncodeMaxRate2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Handl Inst decodes back to what was encoded, and leaves nothing over *)
RoundTripHandlInst2 ==
    \A message \in CheckedHandlInst2 :
        LET read == DecodeHandlInst2(EncodeHandlInst2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reprice Reason decodes back to what was encoded, and leaves nothing over *)
RoundTripRepriceReason2 ==
    \A message \in CheckedRepriceReason2 :
        LET read == DecodeRepriceReason2(EncodeRepriceReason2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Nbbo Setter decodes back to what was encoded, and leaves nothing over *)
RoundTripNbboSetter2 ==
    \A message \in CheckedNbboSetter2 :
        LET read == DecodeNbboSetter2(EncodeNbboSetter2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replaced Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplacedAppendage ==
    \A message \in CheckedOrderReplacedAppendage :
        LET read == DecodeOrderReplacedAppendage(EncodeOrderReplacedAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplacedMessage ==
    \A message \in CheckedOrderReplacedMessage :
        LET read == DecodeOrderReplacedMessage(EncodeOrderReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx3 ==
    \A message \in CheckedUserRefIdx3 :
        LET read == DecodeUserRefIdx3(EncodeUserRefIdx3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Canceled Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCanceledAppendage ==
    \A message \in CheckedOrderCanceledAppendage :
        LET read == DecodeOrderCanceledAppendage(EncodeOrderCanceledAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCanceledMessage ==
    \A message \in CheckedOrderCanceledMessage :
        LET read == DecodeOrderCanceledMessage(EncodeOrderCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx4 ==
    \A message \in CheckedUserRefIdx4 :
        LET read == DecodeUserRefIdx4(EncodeUserRefIdx4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Canceled Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripStpCanceledAppendage ==
    \A message \in CheckedStpCanceledAppendage :
        LET read == DecodeStpCanceledAppendage(EncodeStpCanceledAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStpCanceledMessage ==
    \A message \in CheckedStpCanceledMessage :
        LET read == DecodeStpCanceledMessage(EncodeStpCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx5 ==
    \A message \in CheckedUserRefIdx5 :
        LET read == DecodeUserRefIdx5(EncodeUserRefIdx5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execute Match decodes back to what was encoded, and leaves nothing over *)
RoundTripExecuteMatch ==
    \A message \in CheckedExecuteMatch :
        LET read == DecodeExecuteMatch(EncodeExecuteMatch(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Order Id decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryOrderId ==
    \A message \in CheckedSecondaryOrderId :
        LET read == DecodeSecondaryOrderId(EncodeSecondaryOrderId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broker Pref decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokerPref ==
    \A message \in CheckedBrokerPref :
        LET read == DecodeBrokerPref(EncodeBrokerPref(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Principal Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripPrincipalTrade ==
    \A message \in CheckedPrincipalTrade :
        LET read == DecodePrincipalTrade(EncodePrincipalTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wash Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripWashTrade ==
    \A message \in CheckedWashTrade :
        LET read == DecodeWashTrade(EncodeWashTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cum Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripCumRate ==
    \A message \in CheckedCumRate :
        LET read == DecodeCumRate(EncodeCumRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedAppendage ==
    \A message \in CheckedOrderExecutedAppendage :
        LET read == DecodeOrderExecutedAppendage(EncodeOrderExecutedAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx6 ==
    \A message \in CheckedUserRefIdx6 :
        LET read == DecodeUserRefIdx6(EncodeUserRefIdx6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Trade Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedTradeAppendage ==
    \A message \in CheckedCorrectedTradeAppendage :
        LET read == DecodeCorrectedTradeAppendage(EncodeCorrectedTradeAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedTradeMessage ==
    \A message \in CheckedCorrectedTradeMessage :
        LET read == DecodeCorrectedTradeMessage(EncodeCorrectedTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx7 ==
    \A message \in CheckedUserRefIdx7 :
        LET read == DecodeUserRefIdx7(EncodeUserRefIdx7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rejected Order Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectedOrderAppendage ==
    \A message \in CheckedRejectedOrderAppendage :
        LET read == DecodeRejectedOrderAppendage(EncodeRejectedOrderAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rejected Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectedOrderMessage ==
    \A message \in CheckedRejectedOrderMessage :
        LET read == DecodeRejectedOrderMessage(EncodeRejectedOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx8 ==
    \A message \in CheckedUserRefIdx8 :
        LET read == DecodeUserRefIdx8(EncodeUserRefIdx8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Reject Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectAppendage ==
    \A message \in CheckedCancelRejectAppendage :
        LET read == DecodeCancelRejectAppendage(EncodeCancelRejectAppendage(message))
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

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx9 ==
    \A message \in CheckedUserRefIdx9 :
        LET read == DecodeUserRefIdx9(EncodeUserRefIdx9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Up Id decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmUpId2 ==
    \A message \in CheckedFirmUpId2 :
        LET read == DecodeFirmUpId2(EncodeFirmUpId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedAppendage ==
    \A message \in CheckedOrderRestatedAppendage :
        LET read == DecodeOrderRestatedAppendage(EncodeOrderRestatedAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedMessage ==
    \A message \in CheckedOrderRestatedMessage :
        LET read == DecodeOrderRestatedMessage(EncodeOrderRestatedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx10 ==
    \A message \in CheckedUserRefIdx10 :
        LET read == DecodeUserRefIdx10(EncodeUserRefIdx10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Query Response Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryResponseAppendage ==
    \A message \in CheckedAccountQueryResponseAppendage :
        LET read == DecodeAccountQueryResponseAppendage(EncodeAccountQueryResponseAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Query Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryResponseMessageTail ==
    \A message \in CheckedAccountQueryResponseMessageTail :
        LET read == DecodeAccountQueryResponseMessageTail(EncodeAccountQueryResponseMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Query Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryResponseMessage ==
    \A message \in CheckedAccountQueryResponseMessage :
        LET read == DecodeAccountQueryResponseMessage(EncodeAccountQueryResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
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

(* A Order Accepted Optional Value is selected by the Order Accepted Optional Field it is written under *)
SelectsOrderAcceptedOptionalValue ==
    \A message \in CheckedOrderAcceptedOptionalValue :
        LET read == DecodeOrderAcceptedOptionalValue(message.tag, EncodeOrderAcceptedOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Order Replaced Optional Value is selected by the Order Replaced Optional Field it is written under *)
SelectsOrderReplacedOptionalValue ==
    \A message \in CheckedOrderReplacedOptionalValue :
        LET read == DecodeOrderReplacedOptionalValue(message.tag, EncodeOrderReplacedOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Order Canceled Optional Value is selected by the Order Canceled Optional Field it is written under *)
SelectsOrderCanceledOptionalValue ==
    \A message \in CheckedOrderCanceledOptionalValue :
        LET read == DecodeOrderCanceledOptionalValue(message.tag, EncodeOrderCanceledOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Stp Canceled Optional Value is selected by the Stp Canceled Optional Field it is written under *)
SelectsStpCanceledOptionalValue ==
    \A message \in CheckedStpCanceledOptionalValue :
        LET read == DecodeStpCanceledOptionalValue(message.tag, EncodeStpCanceledOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Order Executed Optional Value is selected by the Order Executed Optional Field it is written under *)
SelectsOrderExecutedOptionalValue ==
    \A message \in CheckedOrderExecutedOptionalValue :
        LET read == DecodeOrderExecutedOptionalValue(message.tag, EncodeOrderExecutedOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Corrected Trade Optional Value is selected by the Corrected Trade Optional Field it is written under *)
SelectsCorrectedTradeOptionalValue ==
    \A message \in CheckedCorrectedTradeOptionalValue :
        LET read == DecodeCorrectedTradeOptionalValue(message.tag, EncodeCorrectedTradeOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Rejected Order Optional Value is selected by the Rejected Order Optional Field it is written under *)
SelectsRejectedOrderOptionalValue ==
    \A message \in CheckedRejectedOrderOptionalValue :
        LET read == DecodeRejectedOrderOptionalValue(message.tag, EncodeRejectedOrderOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Cancel Reject Optional Value is selected by the Cancel Reject Optional Field it is written under *)
SelectsCancelRejectOptionalValue ==
    \A message \in CheckedCancelRejectOptionalValue :
        LET read == DecodeCancelRejectOptionalValue(message.tag, EncodeCancelRejectOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Order Restated Optional Value is selected by the Order Restated Optional Field it is written under *)
SelectsOrderRestatedOptionalValue ==
    \A message \in CheckedOrderRestatedOptionalValue :
        LET read == DecodeOrderRestatedOptionalValue(message.tag, EncodeOrderRestatedOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Account Query Response Optional Value is selected by the Account Query Response Optional Field it is written under *)
SelectsAccountQueryResponseOptionalValue ==
    \A message \in CheckedAccountQueryResponseOptionalValue :
        LET read == DecodeAccountQueryResponseOptionalValue(message.tag, EncodeAccountQueryResponseOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Optional Field Length is written from the bytes it frames *)
FramesOrderAcceptedAppendage ==
    \A message \in CheckedOrderAcceptedAppendage :
        LET bytes == EncodeOrderAcceptedAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesOrderReplacedAppendage ==
    \A message \in CheckedOrderReplacedAppendage :
        LET bytes == EncodeOrderReplacedAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesOrderCanceledAppendage ==
    \A message \in CheckedOrderCanceledAppendage :
        LET bytes == EncodeOrderCanceledAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesStpCanceledAppendage ==
    \A message \in CheckedStpCanceledAppendage :
        LET bytes == EncodeStpCanceledAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesOrderExecutedAppendage ==
    \A message \in CheckedOrderExecutedAppendage :
        LET bytes == EncodeOrderExecutedAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesCorrectedTradeAppendage ==
    \A message \in CheckedCorrectedTradeAppendage :
        LET bytes == EncodeCorrectedTradeAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesRejectedOrderAppendage ==
    \A message \in CheckedRejectedOrderAppendage :
        LET bytes == EncodeRejectedOrderAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesCancelRejectAppendage ==
    \A message \in CheckedCancelRejectAppendage :
        LET bytes == EncodeCancelRejectAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesOrderRestatedAppendage ==
    \A message \in CheckedOrderRestatedAppendage :
        LET bytes == EncodeOrderRestatedAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesAccountQueryResponseAppendage ==
    \A message \in CheckedAccountQueryResponseAppendage :
        LET bytes == EncodeAccountQueryResponseAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
