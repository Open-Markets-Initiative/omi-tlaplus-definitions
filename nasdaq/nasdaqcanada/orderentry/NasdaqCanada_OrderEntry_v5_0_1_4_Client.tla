-------------- MODULE NasdaqCanada_OrderEntry_v5_0_1_4_Client --------------
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
(* Note: Unsequenced Data Packet fills what is left of the frame Packet    *)
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
(* Login Request Packet: 46 bytes                                          *)
(***************************************************************************)

LoginRequestPacket ==
    [ username                : Sample(6),
      password                : Sample(10),
      requestedSession        : Sample(10),
      requestedSequenceNumber : Sample(20) ]

EncodeLoginRequestPacket(message) ==
    message.username
        \o message.password
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequestPacket(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(password.rest, 10) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 20) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ username                |-> username.value,
         password                |-> password.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequestPacket ==
    [ username                |-> [i \in 1 .. 6 |-> 0],
      password                |-> [i \in 1 .. 10 |-> 0],
      requestedSession        |-> [i \in 1 .. 10 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestPacket ==
    { ZeroLoginRequestPacket }
        \cup { [ZeroLoginRequestPacket EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSequenceNumber = one] : one \in Sample(20) }

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
(* Enter Order Optional Value, selected by Enter Order Optional Field      *)
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

EnterOrderOptionalValue ==
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

EncodeEnterOrderOptionalValue(message) ==
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

DecodeEnterOrderOptionalValue(tag, bytes) ==
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
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroEnterOrderOptionalValue == [tag |-> UserRefIdxCode, body |-> ZeroUserRefIdx]

(* Each Enter Order Optional Value in turn, at the values the message it names is checked at *)
CheckedEnterOrderOptionalValue ==
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

(***************************************************************************)
(* Enter Order Appendage, framed by Optional Field Length                  *)
(***************************************************************************)

EnterOrderAppendage ==
    [ enterOrderOptionalValue : EnterOrderOptionalValue ]

EncodeEnterOrderAppendageBody(message) ==
    EncodeUIntBE(message.enterOrderOptionalValue.tag, 1)
        \o EncodeEnterOrderOptionalValue(message.enterOrderOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeEnterOrderAppendage(message) ==
    LET body == EncodeEnterOrderAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeEnterOrderAppendageBody(bytes) ==
    LET enterOrderOptionalField == ReadUIntBE(bytes, 1) IN IF ~enterOrderOptionalField.ok THEN Fail ELSE
    LET enterOrderOptionalValue == DecodeEnterOrderOptionalValue(enterOrderOptionalField.value, enterOrderOptionalField.rest) IN IF ~enterOrderOptionalValue.ok THEN Fail ELSE
    Ok([ enterOrderOptionalValue |-> enterOrderOptionalValue.value ], enterOrderOptionalValue.rest)

DecodeEnterOrderAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeEnterOrderAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroEnterOrderAppendage ==
    [ enterOrderOptionalValue |-> ZeroEnterOrderOptionalValue ]

(* Enter Order Appendage at zero, then each field in turn at the values it is checked at *)
CheckedEnterOrderAppendage ==
    { ZeroEnterOrderAppendage }
        \cup { [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = one] : one \in CheckedEnterOrderOptionalValue }

(* A run of Enter Order Appendage, written one after another *)
RECURSIVE EncodeEnterOrderAppendageList(_)
EncodeEnterOrderAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEnterOrderAppendage(Head(messages)) \o EncodeEnterOrderAppendageList(Tail(messages))

(* As many Enter Order Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadEnterOrderAppendageAll(_)
ReadEnterOrderAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeEnterOrderAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEnterOrderAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Enter Order Appendage of each kind, for the lists that carry them *)
OneEnterOrderAppendage ==
    { [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> UserRefIdxCode, body |-> ZeroUserRefIdx]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> AccountCode, body |-> ZeroAccount]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> PegTypeCode, body |-> ZeroPegType]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> MinQtyTypeCode, body |-> ZeroMinQtyType]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> MinQtyCode, body |-> ZeroMinQty]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> MaxFloorCode, body |-> ZeroMaxFloor]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> ExpireTimeCode, body |-> ZeroExpireTime]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> PegOffsetCode, body |-> ZeroPegOffset]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> TargetStrategyCode, body |-> ZeroTargetStrategy]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> OrderOriginationCode, body |-> ZeroOrderOrigination]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> RoutingArrangementIndicatorCode, body |-> ZeroRoutingArrangementIndicator]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> BasketTradeCode, body |-> ZeroBasketTrade]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> ProgramTradeCode, body |-> ZeroProgramTrade]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> JitneyCode, body |-> ZeroJitney]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> GefEligibleCode, body |-> ZeroGefEligible]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> AnonymousCode, body |-> ZeroAnonymous]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> UmirRegulationIdCode, body |-> ZeroUmirRegulationId]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> BypassCode, body |-> ZeroBypass]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> TsxncibCode, body |-> ZeroTsxncib]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> NoTradeFeatCode, body |-> ZeroNoTradeFeat]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> NoTradeKeyCode, body |-> ZeroNoTradeKey]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> ShortMarkingExemptCode, body |-> ZeroShortMarkingExempt]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> PoCommentCode, body |-> ZeroPoComment]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> DisplayRangeCode, body |-> ZeroDisplayRange]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> CustomerAccountCode, body |-> ZeroCustomerAccount]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> AlgorithmIdCode, body |-> ZeroAlgorithmId]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> CustomerLeiCode, body |-> ZeroCustomerLei]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> BrokerLeiCode, body |-> ZeroBrokerLei]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> ConditionalOrderCode, body |-> ZeroConditionalOrder]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> AllowConditionalCode, body |-> ZeroAllowConditional]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> FirmUpIdCode, body |-> ZeroFirmUpId]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> CxdConnectCode, body |-> ZeroCxdConnect]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> PureStreamConnectCode, body |-> ZeroPureStreamConnect]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> MinRateCode, body |-> ZeroMinRate]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> MaxRateCode, body |-> ZeroMaxRate]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> RoutingStrategyCode, body |-> ZeroRoutingStrategy]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> HandlInstCode, body |-> ZeroHandlInst]] }

(***************************************************************************)
(* Enter Order Message                                                     *)
(***************************************************************************)

EnterOrderMessage ==
    [ userRefNum          : Sample(4),
      orderQty            : Sample(4),
      price               : Sample(8),
      side                : Sample(1),
      symbol              : Sample(10),
      timeInForce         : Sample(1),
      exDestination       : Sample(1),
      umirAccountType     : Sample(2),
      umirUserId          : Sample(8),
      enterOrderAppendage : SampleLists(OneEnterOrderAppendage) ]

EncodeEnterOrderMessage(message) ==
    LET payload == EncodeEnterOrderAppendageList(message.enterOrderAppendage)
    IN  message.userRefNum
            \o message.orderQty
            \o message.price
            \o message.side
            \o message.symbol
            \o message.timeInForce
            \o message.exDestination
            \o message.umirAccountType
            \o message.umirUserId
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeEnterOrderMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET orderQty == ReadBytes(userRefNum.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET symbol == ReadBytes(side.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(symbol.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET exDestination == ReadBytes(timeInForce.rest, 1) IN IF ~exDestination.ok THEN Fail ELSE
    LET umirAccountType == ReadBytes(exDestination.rest, 2) IN IF ~umirAccountType.ok THEN Fail ELSE
    LET umirUserId == ReadBytes(umirAccountType.rest, 8) IN IF ~umirUserId.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(umirUserId.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        enterOrderAppendage == ReadEnterOrderAppendageAll(framed)
    IN  IF ~enterOrderAppendage.ok \/ enterOrderAppendage.rest # << >> THEN Fail ELSE
    Ok([ userRefNum          |-> userRefNum.value,
         orderQty            |-> orderQty.value,
         price               |-> price.value,
         side                |-> side.value,
         symbol              |-> symbol.value,
         timeInForce         |-> timeInForce.value,
         exDestination       |-> exDestination.value,
         umirAccountType     |-> umirAccountType.value,
         umirUserId          |-> umirUserId.value,
         enterOrderAppendage |-> enterOrderAppendage.value ], beyond)

ZeroEnterOrderMessage ==
    [ userRefNum          |-> [i \in 1 .. 4 |-> 0],
      orderQty            |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 8 |-> 0],
      side                |-> [i \in 1 .. 1 |-> 0],
      symbol              |-> [i \in 1 .. 10 |-> 0],
      timeInForce         |-> [i \in 1 .. 1 |-> 0],
      exDestination       |-> [i \in 1 .. 1 |-> 0],
      umirAccountType     |-> [i \in 1 .. 2 |-> 0],
      umirUserId          |-> [i \in 1 .. 8 |-> 0],
      enterOrderAppendage |-> << >> ]

(* Enter Order Message at zero, then each field in turn at the values it is checked at *)
CheckedEnterOrderMessage ==
    { ZeroEnterOrderMessage }
        \cup { [ZeroEnterOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.exDestination = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.umirAccountType = one] : one \in Sample(2) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.umirUserId = one] : one \in Sample(8) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.enterOrderAppendage = one] : one \in SampleLists(OneEnterOrderAppendage) }

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
(* Replace Order Request Optional Value, selected by Replace Order Request *)
(* Optional Field                                                          *)
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

ReplaceOrderRequestOptionalValue ==
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

EncodeReplaceOrderRequestOptionalValue(message) ==
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

DecodeReplaceOrderRequestOptionalValue(tag, bytes) ==
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
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroReplaceOrderRequestOptionalValue == [tag |-> UserRefIdxCode2, body |-> ZeroUserRefIdx2]

(* Each Replace Order Request Optional Value in turn, at the values the message it names is checked at *)
CheckedReplaceOrderRequestOptionalValue ==
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

(***************************************************************************)
(* Replace Order Request Appendage, framed by Optional Field Length        *)
(***************************************************************************)

ReplaceOrderRequestAppendage ==
    [ replaceOrderRequestOptionalValue : ReplaceOrderRequestOptionalValue ]

EncodeReplaceOrderRequestAppendageBody(message) ==
    EncodeUIntBE(message.replaceOrderRequestOptionalValue.tag, 1)
        \o EncodeReplaceOrderRequestOptionalValue(message.replaceOrderRequestOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeReplaceOrderRequestAppendage(message) ==
    LET body == EncodeReplaceOrderRequestAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeReplaceOrderRequestAppendageBody(bytes) ==
    LET replaceOrderRequestOptionalField == ReadUIntBE(bytes, 1) IN IF ~replaceOrderRequestOptionalField.ok THEN Fail ELSE
    LET replaceOrderRequestOptionalValue == DecodeReplaceOrderRequestOptionalValue(replaceOrderRequestOptionalField.value, replaceOrderRequestOptionalField.rest) IN IF ~replaceOrderRequestOptionalValue.ok THEN Fail ELSE
    Ok([ replaceOrderRequestOptionalValue |-> replaceOrderRequestOptionalValue.value ], replaceOrderRequestOptionalValue.rest)

DecodeReplaceOrderRequestAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeReplaceOrderRequestAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroReplaceOrderRequestAppendage ==
    [ replaceOrderRequestOptionalValue |-> ZeroReplaceOrderRequestOptionalValue ]

(* Replace Order Request Appendage at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderRequestAppendage ==
    { ZeroReplaceOrderRequestAppendage }
        \cup { [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = one] : one \in CheckedReplaceOrderRequestOptionalValue }

(* A run of Replace Order Request Appendage, written one after another *)
RECURSIVE EncodeReplaceOrderRequestAppendageList(_)
EncodeReplaceOrderRequestAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeReplaceOrderRequestAppendage(Head(messages)) \o EncodeReplaceOrderRequestAppendageList(Tail(messages))

(* As many Replace Order Request Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadReplaceOrderRequestAppendageAll(_)
ReadReplaceOrderRequestAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeReplaceOrderRequestAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadReplaceOrderRequestAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Replace Order Request Appendage of each kind, for the lists that carry them *)
OneReplaceOrderRequestAppendage ==
    { [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> UserRefIdxCode2, body |-> ZeroUserRefIdx2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> MinQtyTypeCode2, body |-> ZeroMinQtyType2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> PegTypeCode2, body |-> ZeroPegType2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> MinQtyCode2, body |-> ZeroMinQty2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> MaxFloorCode2, body |-> ZeroMaxFloor2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> ExpireTimeCode2, body |-> ZeroExpireTime2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> PegOffsetCode2, body |-> ZeroPegOffset2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> TargetStrategyCode2, body |-> ZeroTargetStrategy2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> OrderOriginationCode2, body |-> ZeroOrderOrigination2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> RoutingArrangementIndicatorCode2, body |-> ZeroRoutingArrangementIndicator2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> UmirRegulationIdCode2, body |-> ZeroUmirRegulationId2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> AnonymousCode2, body |-> ZeroAnonymous2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> DisplayRangeCode2, body |-> ZeroDisplayRange2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> CustomerAccountCode2, body |-> ZeroCustomerAccount2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> AlgorithmIdCode2, body |-> ZeroAlgorithmId2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> CustomerLeiCode2, body |-> ZeroCustomerLei2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> BrokerLeiCode2, body |-> ZeroBrokerLei2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> AllowConditionalCode2, body |-> ZeroAllowConditional2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> CxdConnectCode2, body |-> ZeroCxdConnect2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> PureStreamConnectCode2, body |-> ZeroPureStreamConnect2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> MinRateCode2, body |-> ZeroMinRate2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> MaxRateCode2, body |-> ZeroMaxRate2]],
      [ZeroReplaceOrderRequestAppendage EXCEPT !.replaceOrderRequestOptionalValue = [tag |-> HandlInstCode2, body |-> ZeroHandlInst2]] }

(***************************************************************************)
(* Replace Order Request Message                                           *)
(***************************************************************************)

ReplaceOrderRequestMessage ==
    [ origUserRefNum               : Sample(4),
      userRefNum                   : Sample(4),
      orderQty                     : Sample(4),
      price                        : Sample(8),
      side                         : Sample(1),
      timeInForce                  : Sample(1),
      replaceOrderRequestAppendage : SampleLists(OneReplaceOrderRequestAppendage) ]

EncodeReplaceOrderRequestMessage(message) ==
    LET payload == EncodeReplaceOrderRequestAppendageList(message.replaceOrderRequestAppendage)
    IN  message.origUserRefNum
            \o message.userRefNum
            \o message.orderQty
            \o message.price
            \o message.side
            \o message.timeInForce
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeReplaceOrderRequestMessage(bytes) ==
    LET origUserRefNum == ReadBytes(bytes, 4) IN IF ~origUserRefNum.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(origUserRefNum.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET orderQty == ReadBytes(userRefNum.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET price == ReadBytes(orderQty.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(side.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(timeInForce.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        replaceOrderRequestAppendage == ReadReplaceOrderRequestAppendageAll(framed)
    IN  IF ~replaceOrderRequestAppendage.ok \/ replaceOrderRequestAppendage.rest # << >> THEN Fail ELSE
    Ok([ origUserRefNum               |-> origUserRefNum.value,
         userRefNum                   |-> userRefNum.value,
         orderQty                     |-> orderQty.value,
         price                        |-> price.value,
         side                         |-> side.value,
         timeInForce                  |-> timeInForce.value,
         replaceOrderRequestAppendage |-> replaceOrderRequestAppendage.value ], beyond)

ZeroReplaceOrderRequestMessage ==
    [ origUserRefNum               |-> [i \in 1 .. 4 |-> 0],
      userRefNum                   |-> [i \in 1 .. 4 |-> 0],
      orderQty                     |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      side                         |-> [i \in 1 .. 1 |-> 0],
      timeInForce                  |-> [i \in 1 .. 1 |-> 0],
      replaceOrderRequestAppendage |-> << >> ]

(* Replace Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderRequestMessage ==
    { ZeroReplaceOrderRequestMessage }
        \cup { [ZeroReplaceOrderRequestMessage EXCEPT !.origUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderRequestMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderRequestMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderRequestMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroReplaceOrderRequestMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroReplaceOrderRequestMessage EXCEPT !.replaceOrderRequestAppendage = one] : one \in SampleLists(OneReplaceOrderRequestAppendage) }

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
(* Cancel Order Request Optional Value, selected by Cancel Order Request   *)
(* Optional Field                                                          *)
(***************************************************************************)

UserRefIdxCode3 == 37  \* 0x25

CancelOrderRequestOptionalValue ==
    [ tag : {UserRefIdxCode3}, body : UserRefIdx3 ]

EncodeCancelOrderRequestOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode3 -> EncodeUserRefIdx3(message.body)

DecodeCancelOrderRequestOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode3 -> DecodeUserRefIdx3(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCancelOrderRequestOptionalValue == [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]

(* Each Cancel Order Request Optional Value in turn, at the values the message it names is checked at *)
CheckedCancelOrderRequestOptionalValue ==
    { [tag |-> UserRefIdxCode3, body |-> one] : one \in CheckedUserRefIdx3 }

(***************************************************************************)
(* Cancel Order Request Appendage, framed by Optional Field Length         *)
(***************************************************************************)

CancelOrderRequestAppendage ==
    [ cancelOrderRequestOptionalValue : CancelOrderRequestOptionalValue ]

EncodeCancelOrderRequestAppendageBody(message) ==
    EncodeUIntBE(message.cancelOrderRequestOptionalValue.tag, 1)
        \o EncodeCancelOrderRequestOptionalValue(message.cancelOrderRequestOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeCancelOrderRequestAppendage(message) ==
    LET body == EncodeCancelOrderRequestAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeCancelOrderRequestAppendageBody(bytes) ==
    LET cancelOrderRequestOptionalField == ReadUIntBE(bytes, 1) IN IF ~cancelOrderRequestOptionalField.ok THEN Fail ELSE
    LET cancelOrderRequestOptionalValue == DecodeCancelOrderRequestOptionalValue(cancelOrderRequestOptionalField.value, cancelOrderRequestOptionalField.rest) IN IF ~cancelOrderRequestOptionalValue.ok THEN Fail ELSE
    Ok([ cancelOrderRequestOptionalValue |-> cancelOrderRequestOptionalValue.value ], cancelOrderRequestOptionalValue.rest)

DecodeCancelOrderRequestAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeCancelOrderRequestAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroCancelOrderRequestAppendage ==
    [ cancelOrderRequestOptionalValue |-> ZeroCancelOrderRequestOptionalValue ]

(* Cancel Order Request Appendage at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderRequestAppendage ==
    { ZeroCancelOrderRequestAppendage }
        \cup { [ZeroCancelOrderRequestAppendage EXCEPT !.cancelOrderRequestOptionalValue = one] : one \in CheckedCancelOrderRequestOptionalValue }

(* A run of Cancel Order Request Appendage, written one after another *)
RECURSIVE EncodeCancelOrderRequestAppendageList(_)
EncodeCancelOrderRequestAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCancelOrderRequestAppendage(Head(messages)) \o EncodeCancelOrderRequestAppendageList(Tail(messages))

(* As many Cancel Order Request Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadCancelOrderRequestAppendageAll(_)
ReadCancelOrderRequestAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeCancelOrderRequestAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCancelOrderRequestAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cancel Order Request Appendage of each kind, for the lists that carry them *)
OneCancelOrderRequestAppendage ==
    { [ZeroCancelOrderRequestAppendage EXCEPT !.cancelOrderRequestOptionalValue = [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]] }

(***************************************************************************)
(* Cancel Order Request Message                                            *)
(***************************************************************************)

CancelOrderRequestMessage ==
    [ userRefNum                  : Sample(4),
      orderQty                    : Sample(4),
      cancelOrderRequestAppendage : SampleLists(OneCancelOrderRequestAppendage) ]

EncodeCancelOrderRequestMessage(message) ==
    LET payload == EncodeCancelOrderRequestAppendageList(message.cancelOrderRequestAppendage)
    IN  message.userRefNum
            \o message.orderQty
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeCancelOrderRequestMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET orderQty == ReadBytes(userRefNum.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(orderQty.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        cancelOrderRequestAppendage == ReadCancelOrderRequestAppendageAll(framed)
    IN  IF ~cancelOrderRequestAppendage.ok \/ cancelOrderRequestAppendage.rest # << >> THEN Fail ELSE
    Ok([ userRefNum                  |-> userRefNum.value,
         orderQty                    |-> orderQty.value,
         cancelOrderRequestAppendage |-> cancelOrderRequestAppendage.value ], beyond)

ZeroCancelOrderRequestMessage ==
    [ userRefNum                  |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      cancelOrderRequestAppendage |-> << >> ]

(* Cancel Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderRequestMessage ==
    { ZeroCancelOrderRequestMessage }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderRequestMessage EXCEPT !.cancelOrderRequestAppendage = one] : one \in SampleLists(OneCancelOrderRequestAppendage) }

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
(* Account Query Request Optional Value, selected by Account Query Request *)
(* Optional Field                                                          *)
(***************************************************************************)

UserRefIdxCode4 == 37  \* 0x25

AccountQueryRequestOptionalValue ==
    [ tag : {UserRefIdxCode4}, body : UserRefIdx4 ]

EncodeAccountQueryRequestOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode4 -> EncodeUserRefIdx4(message.body)

DecodeAccountQueryRequestOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode4 -> DecodeUserRefIdx4(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAccountQueryRequestOptionalValue == [tag |-> UserRefIdxCode4, body |-> ZeroUserRefIdx4]

(* Each Account Query Request Optional Value in turn, at the values the message it names is checked at *)
CheckedAccountQueryRequestOptionalValue ==
    { [tag |-> UserRefIdxCode4, body |-> one] : one \in CheckedUserRefIdx4 }

(***************************************************************************)
(* Account Query Request Appendage, framed by Optional Field Length        *)
(***************************************************************************)

AccountQueryRequestAppendage ==
    [ accountQueryRequestOptionalValue : AccountQueryRequestOptionalValue ]

EncodeAccountQueryRequestAppendageBody(message) ==
    EncodeUIntBE(message.accountQueryRequestOptionalValue.tag, 1)
        \o EncodeAccountQueryRequestOptionalValue(message.accountQueryRequestOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeAccountQueryRequestAppendage(message) ==
    LET body == EncodeAccountQueryRequestAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeAccountQueryRequestAppendageBody(bytes) ==
    LET accountQueryRequestOptionalField == ReadUIntBE(bytes, 1) IN IF ~accountQueryRequestOptionalField.ok THEN Fail ELSE
    LET accountQueryRequestOptionalValue == DecodeAccountQueryRequestOptionalValue(accountQueryRequestOptionalField.value, accountQueryRequestOptionalField.rest) IN IF ~accountQueryRequestOptionalValue.ok THEN Fail ELSE
    Ok([ accountQueryRequestOptionalValue |-> accountQueryRequestOptionalValue.value ], accountQueryRequestOptionalValue.rest)

DecodeAccountQueryRequestAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeAccountQueryRequestAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroAccountQueryRequestAppendage ==
    [ accountQueryRequestOptionalValue |-> ZeroAccountQueryRequestOptionalValue ]

(* Account Query Request Appendage at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryRequestAppendage ==
    { ZeroAccountQueryRequestAppendage }
        \cup { [ZeroAccountQueryRequestAppendage EXCEPT !.accountQueryRequestOptionalValue = one] : one \in CheckedAccountQueryRequestOptionalValue }

(* A run of Account Query Request Appendage, written one after another *)
RECURSIVE EncodeAccountQueryRequestAppendageList(_)
EncodeAccountQueryRequestAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAccountQueryRequestAppendage(Head(messages)) \o EncodeAccountQueryRequestAppendageList(Tail(messages))

(* As many Account Query Request Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadAccountQueryRequestAppendageAll(_)
ReadAccountQueryRequestAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeAccountQueryRequestAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAccountQueryRequestAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Account Query Request Appendage of each kind, for the lists that carry them *)
OneAccountQueryRequestAppendage ==
    { [ZeroAccountQueryRequestAppendage EXCEPT !.accountQueryRequestOptionalValue = [tag |-> UserRefIdxCode4, body |-> ZeroUserRefIdx4]] }

(***************************************************************************)
(* Account Query Request Message                                           *)
(***************************************************************************)

AccountQueryRequestMessageTail ==
    [ accountQueryRequestAppendage : SampleLists(OneAccountQueryRequestAppendage) ]

EncodeAccountQueryRequestMessageTail(message) ==
    LET payload == EncodeAccountQueryRequestAppendageList(message.accountQueryRequestAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeAccountQueryRequestMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        accountQueryRequestAppendage == ReadAccountQueryRequestAppendageAll(framed)
    IN  IF ~accountQueryRequestAppendage.ok \/ accountQueryRequestAppendage.rest # << >> THEN Fail ELSE
    Ok([ accountQueryRequestAppendage |-> accountQueryRequestAppendage.value ], beyond)

ZeroAccountQueryRequestMessageTail ==
    [ accountQueryRequestAppendage |-> << >> ]

(* Account Query Request Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryRequestMessageTail ==
    { ZeroAccountQueryRequestMessageTail }
        \cup { [ZeroAccountQueryRequestMessageTail EXCEPT !.accountQueryRequestAppendage = one] : one \in SampleLists(OneAccountQueryRequestAppendage) }

(* Account Query Request Message runs on only when bytes remain, so it is there or it is not *)
WithoutAccountQueryRequestMessageTail == [there |-> FALSE, value |-> ZeroAccountQueryRequestMessageTail]

MaybeAccountQueryRequestMessageTail ==
    { WithoutAccountQueryRequestMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedAccountQueryRequestMessageTail }

ReadAccountQueryRequestMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutAccountQueryRequestMessageTail, << >>)
    ELSE LET one == DecodeAccountQueryRequestMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Account Query Request Message                                           *)
(***************************************************************************)

AccountQueryRequestMessage ==
    [ accountQueryRequestMessageTail : MaybeAccountQueryRequestMessageTail ]

EncodeAccountQueryRequestMessage(message) ==
    IF message.accountQueryRequestMessageTail.there THEN EncodeAccountQueryRequestMessageTail(message.accountQueryRequestMessageTail.value) ELSE << >>

DecodeAccountQueryRequestMessage(bytes) ==
    LET accountQueryRequestMessageTail == ReadAccountQueryRequestMessageTailMaybe(bytes) IN IF ~accountQueryRequestMessageTail.ok THEN Fail ELSE
    Ok([ accountQueryRequestMessageTail |-> accountQueryRequestMessageTail.value ], accountQueryRequestMessageTail.rest)

ZeroAccountQueryRequestMessage ==
    [ accountQueryRequestMessageTail |-> WithoutAccountQueryRequestMessageTail ]

(* Account Query Request Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryRequestMessage ==
    { ZeroAccountQueryRequestMessage }
        \cup { [ZeroAccountQueryRequestMessage EXCEPT !.accountQueryRequestMessageTail = one] : one \in MaybeAccountQueryRequestMessageTail }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

EnterOrderMessageCode == 79  \* "O"
ReplaceOrderRequestMessageCode == 85  \* "U"
CancelOrderRequestMessageCode == 88  \* "X"
AccountQueryRequestMessageCode == 81  \* "Q"

UnsequencedMessage ==
    [ tag : {EnterOrderMessageCode}, body : EnterOrderMessage ]
        \cup [ tag : {ReplaceOrderRequestMessageCode}, body : ReplaceOrderRequestMessage ]
        \cup [ tag : {CancelOrderRequestMessageCode}, body : CancelOrderRequestMessage ]
        \cup [ tag : {AccountQueryRequestMessageCode}, body : AccountQueryRequestMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = EnterOrderMessageCode -> EncodeEnterOrderMessage(message.body)
      [] message.tag = ReplaceOrderRequestMessageCode -> EncodeReplaceOrderRequestMessage(message.body)
      [] message.tag = CancelOrderRequestMessageCode -> EncodeCancelOrderRequestMessage(message.body)
      [] message.tag = AccountQueryRequestMessageCode -> EncodeAccountQueryRequestMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = EnterOrderMessageCode -> DecodeEnterOrderMessage(bytes)
              [] tag = ReplaceOrderRequestMessageCode -> DecodeReplaceOrderRequestMessage(bytes)
              [] tag = CancelOrderRequestMessageCode -> DecodeCancelOrderRequestMessage(bytes)
              [] tag = AccountQueryRequestMessageCode -> DecodeAccountQueryRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> EnterOrderMessageCode, body |-> ZeroEnterOrderMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> EnterOrderMessageCode, body |-> one] : one \in CheckedEnterOrderMessage }
        \cup { [tag |-> ReplaceOrderRequestMessageCode, body |-> one] : one \in CheckedReplaceOrderRequestMessage }
        \cup { [tag |-> CancelOrderRequestMessageCode, body |-> one] : one \in CheckedCancelOrderRequestMessage }
        \cup { [tag |-> AccountQueryRequestMessageCode, body |-> one] : one \in CheckedAccountQueryRequestMessage }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 1)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Payload, selected by Client Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginRequestPacketCode == 76  \* "L"
UnsequencedDataPacketCode == 85  \* "U"
ClientHeartbeatCode == 82  \* "R"
LogoutRequestCode == 79  \* "O"

ClientPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]

EncodeClientPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = LogoutRequestCode -> << >>

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Client Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ClientSoupBinTcpPacket ==
    [ clientPayload : ClientPayload ]

EncodeClientSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientSoupBinTcpPacket(message) ==
    LET body == EncodeClientSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeClientSoupBinTcpPacketBody(bytes) ==
    LET clientPacketType == ReadUIntBE(bytes, 1) IN IF ~clientPacketType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(clientPacketType.value, clientPacketType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeClientSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSoupBinTcpPacket ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientSoupBinTcpPacket ==
    { ZeroClientSoupBinTcpPacket }
        \cup { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeClientSoupBinTcpPacketList(_)
EncodeClientSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSoupBinTcpPacket(Head(messages)) \o EncodeClientSoupBinTcpPacketList(Tail(messages))

(* As many Client Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSoupBinTcpPacketAll(_)
ReadClientSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneClientSoupBinTcpPacket ==
    { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LoginRequestPacketCode, body |-> ZeroLoginRequestPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSoupBinTcpPacket : SampleLists(OneClientSoupBinTcpPacket) ]

EncodeClientPacket(message) ==
    EncodeClientSoupBinTcpPacketList(message.clientSoupBinTcpPacket)

DecodeClientPacket(bytes) ==
    LET clientSoupBinTcpPacket == ReadClientSoupBinTcpPacketAll(bytes) IN IF ~clientSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ clientSoupBinTcpPacket |-> clientSoupBinTcpPacket.value ], clientSoupBinTcpPacket.rest)

ZeroClientPacket ==
    [ clientSoupBinTcpPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSoupBinTcpPacket = one] : one \in SampleLists(OneClientSoupBinTcpPacket) }

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

(* Every Login Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestPacket ==
    \A message \in CheckedLoginRequestPacket :
        LET read == DecodeLoginRequestPacket(EncodeLoginRequestPacket(message))
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

(* Every Enter Order Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterOrderAppendage ==
    \A message \in CheckedEnterOrderAppendage :
        LET read == DecodeEnterOrderAppendage(EncodeEnterOrderAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterOrderMessage ==
    \A message \in CheckedEnterOrderMessage :
        LET read == DecodeEnterOrderMessage(EncodeEnterOrderMessage(message))
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

(* Every Replace Order Request Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceOrderRequestAppendage ==
    \A message \in CheckedReplaceOrderRequestAppendage :
        LET read == DecodeReplaceOrderRequestAppendage(EncodeReplaceOrderRequestAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replace Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceOrderRequestMessage ==
    \A message \in CheckedReplaceOrderRequestMessage :
        LET read == DecodeReplaceOrderRequestMessage(EncodeReplaceOrderRequestMessage(message))
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

(* Every Cancel Order Request Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderRequestAppendage ==
    \A message \in CheckedCancelOrderRequestAppendage :
        LET read == DecodeCancelOrderRequestAppendage(EncodeCancelOrderRequestAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderRequestMessage ==
    \A message \in CheckedCancelOrderRequestMessage :
        LET read == DecodeCancelOrderRequestMessage(EncodeCancelOrderRequestMessage(message))
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

(* Every Account Query Request Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryRequestAppendage ==
    \A message \in CheckedAccountQueryRequestAppendage :
        LET read == DecodeAccountQueryRequestAppendage(EncodeAccountQueryRequestAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Query Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryRequestMessageTail ==
    \A message \in CheckedAccountQueryRequestMessageTail :
        LET read == DecodeAccountQueryRequestMessageTail(EncodeAccountQueryRequestMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Query Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryRequestMessage ==
    \A message \in CheckedAccountQueryRequestMessage :
        LET read == DecodeAccountQueryRequestMessage(EncodeAccountQueryRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET read == DecodeClientSoupBinTcpPacket(EncodeClientSoupBinTcpPacket(message))
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

(* A Enter Order Optional Value is selected by the Enter Order Optional Field it is written under *)
SelectsEnterOrderOptionalValue ==
    \A message \in CheckedEnterOrderOptionalValue :
        LET read == DecodeEnterOrderOptionalValue(message.tag, EncodeEnterOrderOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Replace Order Request Optional Value is selected by the Replace Order Request Optional Field it is written under *)
SelectsReplaceOrderRequestOptionalValue ==
    \A message \in CheckedReplaceOrderRequestOptionalValue :
        LET read == DecodeReplaceOrderRequestOptionalValue(message.tag, EncodeReplaceOrderRequestOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Cancel Order Request Optional Value is selected by the Cancel Order Request Optional Field it is written under *)
SelectsCancelOrderRequestOptionalValue ==
    \A message \in CheckedCancelOrderRequestOptionalValue :
        LET read == DecodeCancelOrderRequestOptionalValue(message.tag, EncodeCancelOrderRequestOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Account Query Request Optional Value is selected by the Account Query Request Optional Field it is written under *)
SelectsAccountQueryRequestOptionalValue ==
    \A message \in CheckedAccountQueryRequestOptionalValue :
        LET read == DecodeAccountQueryRequestOptionalValue(message.tag, EncodeAccountQueryRequestOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(message.tag, EncodeUnsequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Payload is selected by the Client Packet Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Optional Field Length is written from the bytes it frames *)
FramesEnterOrderAppendage ==
    \A message \in CheckedEnterOrderAppendage :
        LET bytes == EncodeEnterOrderAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesReplaceOrderRequestAppendage ==
    \A message \in CheckedReplaceOrderRequestAppendage :
        LET bytes == EncodeReplaceOrderRequestAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesCancelOrderRequestAppendage ==
    \A message \in CheckedCancelOrderRequestAppendage :
        LET bytes == EncodeCancelOrderRequestAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesAccountQueryRequestAppendage ==
    \A message \in CheckedAccountQueryRequestAppendage :
        LET bytes == EncodeAccountQueryRequestAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Packet Length is written from the bytes it frames *)
FramesClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET bytes == EncodeClientSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
