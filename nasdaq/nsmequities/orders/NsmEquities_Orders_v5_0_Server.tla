------------------ MODULE NsmEquities_Orders_v5_0_Server -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Orders v5.0                                                    *)
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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

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
(* Firm: 4 bytes                                                           *)
(***************************************************************************)

Firm ==
    [ firm : Sample(4) ]

EncodeFirm(message) ==
    message.firm

DecodeFirm(bytes) ==
    LET firm == ReadBytes(bytes, 4) IN IF ~firm.ok THEN Fail ELSE
    Ok([ firm |-> firm.value ], firm.rest)

ZeroFirm ==
    [ firm |-> [i \in 1 .. 4 |-> 0] ]

(* Firm at zero, then each field in turn at the values it is checked at *)
CheckedFirm ==
    { ZeroFirm }
        \cup { [ZeroFirm EXCEPT !.firm = one] : one \in Sample(4) }

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
(* Customer Type: 1 bytes                                                  *)
(***************************************************************************)

CustomerType ==
    [ customerType : Sample(1) ]

EncodeCustomerType(message) ==
    message.customerType

DecodeCustomerType(bytes) ==
    LET customerType == ReadBytes(bytes, 1) IN IF ~customerType.ok THEN Fail ELSE
    Ok([ customerType |-> customerType.value ], customerType.rest)

ZeroCustomerType ==
    [ customerType |-> [i \in 1 .. 1 |-> 0] ]

(* Customer Type at zero, then each field in turn at the values it is checked at *)
CheckedCustomerType ==
    { ZeroCustomerType }
        \cup { [ZeroCustomerType EXCEPT !.customerType = one] : one \in Sample(1) }

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
(* Price Type: 1 bytes                                                     *)
(***************************************************************************)

PriceType ==
    [ priceType : Sample(1) ]

EncodePriceType(message) ==
    message.priceType

DecodePriceType(bytes) ==
    LET priceType == ReadBytes(bytes, 1) IN IF ~priceType.ok THEN Fail ELSE
    Ok([ priceType |-> priceType.value ], priceType.rest)

ZeroPriceType ==
    [ priceType |-> [i \in 1 .. 1 |-> 0] ]

(* Price Type at zero, then each field in turn at the values it is checked at *)
CheckedPriceType ==
    { ZeroPriceType }
        \cup { [ZeroPriceType EXCEPT !.priceType = one] : one \in Sample(1) }

(***************************************************************************)
(* Peg Offset: 4 bytes                                                     *)
(***************************************************************************)

PegOffset ==
    [ pegOffset : Sample(4) ]

EncodePegOffset(message) ==
    message.pegOffset

DecodePegOffset(bytes) ==
    LET pegOffset == ReadBytes(bytes, 4) IN IF ~pegOffset.ok THEN Fail ELSE
    Ok([ pegOffset |-> pegOffset.value ], pegOffset.rest)

ZeroPegOffset ==
    [ pegOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Peg Offset at zero, then each field in turn at the values it is checked at *)
CheckedPegOffset ==
    { ZeroPegOffset }
        \cup { [ZeroPegOffset EXCEPT !.pegOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Discretion Price: 8 bytes                                               *)
(***************************************************************************)

DiscretionPrice ==
    [ discretionPrice : Sample(8) ]

EncodeDiscretionPrice(message) ==
    message.discretionPrice

DecodeDiscretionPrice(bytes) ==
    LET discretionPrice == ReadBytes(bytes, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ discretionPrice |-> discretionPrice.value ], discretionPrice.rest)

ZeroDiscretionPrice ==
    [ discretionPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Discretion Price at zero, then each field in turn at the values it is checked at *)
CheckedDiscretionPrice ==
    { ZeroDiscretionPrice }
        \cup { [ZeroDiscretionPrice EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Discretion Price Type: 1 bytes                                          *)
(***************************************************************************)

DiscretionPriceType ==
    [ discretionPriceType : Sample(1) ]

EncodeDiscretionPriceType(message) ==
    message.discretionPriceType

DecodeDiscretionPriceType(bytes) ==
    LET discretionPriceType == ReadBytes(bytes, 1) IN IF ~discretionPriceType.ok THEN Fail ELSE
    Ok([ discretionPriceType |-> discretionPriceType.value ], discretionPriceType.rest)

ZeroDiscretionPriceType ==
    [ discretionPriceType |-> [i \in 1 .. 1 |-> 0] ]

(* Discretion Price Type at zero, then each field in turn at the values it is checked at *)
CheckedDiscretionPriceType ==
    { ZeroDiscretionPriceType }
        \cup { [ZeroDiscretionPriceType EXCEPT !.discretionPriceType = one] : one \in Sample(1) }

(***************************************************************************)
(* Discretion Peg Offset: 4 bytes                                          *)
(***************************************************************************)

DiscretionPegOffset ==
    [ discretionPegOffset : Sample(4) ]

EncodeDiscretionPegOffset(message) ==
    message.discretionPegOffset

DecodeDiscretionPegOffset(bytes) ==
    LET discretionPegOffset == ReadBytes(bytes, 4) IN IF ~discretionPegOffset.ok THEN Fail ELSE
    Ok([ discretionPegOffset |-> discretionPegOffset.value ], discretionPegOffset.rest)

ZeroDiscretionPegOffset ==
    [ discretionPegOffset |-> [i \in 1 .. 4 |-> 0] ]

(* Discretion Peg Offset at zero, then each field in turn at the values it is checked at *)
CheckedDiscretionPegOffset ==
    { ZeroDiscretionPegOffset }
        \cup { [ZeroDiscretionPegOffset EXCEPT !.discretionPegOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Post Only: 1 bytes                                                      *)
(***************************************************************************)

PostOnly ==
    [ postOnly : Sample(1) ]

EncodePostOnly(message) ==
    message.postOnly

DecodePostOnly(bytes) ==
    LET postOnly == ReadBytes(bytes, 1) IN IF ~postOnly.ok THEN Fail ELSE
    Ok([ postOnly |-> postOnly.value ], postOnly.rest)

ZeroPostOnly ==
    [ postOnly |-> [i \in 1 .. 1 |-> 0] ]

(* Post Only at zero, then each field in turn at the values it is checked at *)
CheckedPostOnly ==
    { ZeroPostOnly }
        \cup { [ZeroPostOnly EXCEPT !.postOnly = one] : one \in Sample(1) }

(***************************************************************************)
(* Random Reserves: 4 bytes                                                *)
(***************************************************************************)

RandomReserves ==
    [ randomReserves : Sample(4) ]

EncodeRandomReserves(message) ==
    message.randomReserves

DecodeRandomReserves(bytes) ==
    LET randomReserves == ReadBytes(bytes, 4) IN IF ~randomReserves.ok THEN Fail ELSE
    Ok([ randomReserves |-> randomReserves.value ], randomReserves.rest)

ZeroRandomReserves ==
    [ randomReserves |-> [i \in 1 .. 4 |-> 0] ]

(* Random Reserves at zero, then each field in turn at the values it is checked at *)
CheckedRandomReserves ==
    { ZeroRandomReserves }
        \cup { [ZeroRandomReserves EXCEPT !.randomReserves = one] : one \in Sample(4) }

(***************************************************************************)
(* Route: 4 bytes                                                          *)
(***************************************************************************)

Route ==
    [ route : Sample(4) ]

EncodeRoute(message) ==
    message.route

DecodeRoute(bytes) ==
    LET route == ReadBytes(bytes, 4) IN IF ~route.ok THEN Fail ELSE
    Ok([ route |-> route.value ], route.rest)

ZeroRoute ==
    [ route |-> [i \in 1 .. 4 |-> 0] ]

(* Route at zero, then each field in turn at the values it is checked at *)
CheckedRoute ==
    { ZeroRoute }
        \cup { [ZeroRoute EXCEPT !.route = one] : one \in Sample(4) }

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
(* Trade Now: 1 bytes                                                      *)
(***************************************************************************)

TradeNow ==
    [ tradeNow : Sample(1) ]

EncodeTradeNow(message) ==
    message.tradeNow

DecodeTradeNow(bytes) ==
    LET tradeNow == ReadBytes(bytes, 1) IN IF ~tradeNow.ok THEN Fail ELSE
    Ok([ tradeNow |-> tradeNow.value ], tradeNow.rest)

ZeroTradeNow ==
    [ tradeNow |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Now at zero, then each field in turn at the values it is checked at *)
CheckedTradeNow ==
    { ZeroTradeNow }
        \cup { [ZeroTradeNow EXCEPT !.tradeNow = one] : one \in Sample(1) }

(***************************************************************************)
(* Handle Inst: 1 bytes                                                    *)
(***************************************************************************)

HandleInst ==
    [ handleInst : Sample(1) ]

EncodeHandleInst(message) ==
    message.handleInst

DecodeHandleInst(bytes) ==
    LET handleInst == ReadBytes(bytes, 1) IN IF ~handleInst.ok THEN Fail ELSE
    Ok([ handleInst |-> handleInst.value ], handleInst.rest)

ZeroHandleInst ==
    [ handleInst |-> [i \in 1 .. 1 |-> 0] ]

(* Handle Inst at zero, then each field in turn at the values it is checked at *)
CheckedHandleInst ==
    { ZeroHandleInst }
        \cup { [ZeroHandleInst EXCEPT !.handleInst = one] : one \in Sample(1) }

(***************************************************************************)
(* Bbo Weight Indicator: 1 bytes                                           *)
(***************************************************************************)

BboWeightIndicator ==
    [ bboWeightIndicator : Sample(1) ]

EncodeBboWeightIndicator(message) ==
    message.bboWeightIndicator

DecodeBboWeightIndicator(bytes) ==
    LET bboWeightIndicator == ReadBytes(bytes, 1) IN IF ~bboWeightIndicator.ok THEN Fail ELSE
    Ok([ bboWeightIndicator |-> bboWeightIndicator.value ], bboWeightIndicator.rest)

ZeroBboWeightIndicator ==
    [ bboWeightIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Bbo Weight Indicator at zero, then each field in turn at the values it is checked at *)
CheckedBboWeightIndicator ==
    { ZeroBboWeightIndicator }
        \cup { [ZeroBboWeightIndicator EXCEPT !.bboWeightIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Group Id: 2 bytes                                                       *)
(***************************************************************************)

GroupId ==
    [ groupId : Sample(2) ]

EncodeGroupId(message) ==
    message.groupId

DecodeGroupId(bytes) ==
    LET groupId == ReadBytes(bytes, 2) IN IF ~groupId.ok THEN Fail ELSE
    Ok([ groupId |-> groupId.value ], groupId.rest)

ZeroGroupId ==
    [ groupId |-> [i \in 1 .. 2 |-> 0] ]

(* Group Id at zero, then each field in turn at the values it is checked at *)
CheckedGroupId ==
    { ZeroGroupId }
        \cup { [ZeroGroupId EXCEPT !.groupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Shares Located: 1 bytes                                                 *)
(***************************************************************************)

SharesLocated ==
    [ sharesLocated : Sample(1) ]

EncodeSharesLocated(message) ==
    message.sharesLocated

DecodeSharesLocated(bytes) ==
    LET sharesLocated == ReadBytes(bytes, 1) IN IF ~sharesLocated.ok THEN Fail ELSE
    Ok([ sharesLocated |-> sharesLocated.value ], sharesLocated.rest)

ZeroSharesLocated ==
    [ sharesLocated |-> [i \in 1 .. 1 |-> 0] ]

(* Shares Located at zero, then each field in turn at the values it is checked at *)
CheckedSharesLocated ==
    { ZeroSharesLocated }
        \cup { [ZeroSharesLocated EXCEPT !.sharesLocated = one] : one \in Sample(1) }

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
(* Aiq Strategy: 1 bytes                                                   *)
(***************************************************************************)

AiqStrategy ==
    [ aiqStrategy : Sample(1) ]

EncodeAiqStrategy(message) ==
    message.aiqStrategy

DecodeAiqStrategy(bytes) ==
    LET aiqStrategy == ReadBytes(bytes, 1) IN IF ~aiqStrategy.ok THEN Fail ELSE
    Ok([ aiqStrategy |-> aiqStrategy.value ], aiqStrategy.rest)

ZeroAiqStrategy ==
    [ aiqStrategy |-> [i \in 1 .. 1 |-> 0] ]

(* Aiq Strategy at zero, then each field in turn at the values it is checked at *)
CheckedAiqStrategy ==
    { ZeroAiqStrategy }
        \cup { [ZeroAiqStrategy EXCEPT !.aiqStrategy = one] : one \in Sample(1) }

(***************************************************************************)
(* Aiq Group Id: 2 bytes                                                   *)
(***************************************************************************)

AiqGroupId ==
    [ aiqGroupId : Sample(2) ]

EncodeAiqGroupId(message) ==
    message.aiqGroupId

DecodeAiqGroupId(bytes) ==
    LET aiqGroupId == ReadBytes(bytes, 2) IN IF ~aiqGroupId.ok THEN Fail ELSE
    Ok([ aiqGroupId |-> aiqGroupId.value ], aiqGroupId.rest)

ZeroAiqGroupId ==
    [ aiqGroupId |-> [i \in 1 .. 2 |-> 0] ]

(* Aiq Group Id at zero, then each field in turn at the values it is checked at *)
CheckedAiqGroupId ==
    { ZeroAiqGroupId }
        \cup { [ZeroAiqGroupId EXCEPT !.aiqGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Accepted Optional Value, selected by Order Accepted Optional      *)
(* Field                                                                   *)
(***************************************************************************)

FirmCode == 2  \* 0x02
MinQtyCode == 3  \* 0x03
CustomerTypeCode == 4  \* 0x04
MaxFloorCode == 5  \* 0x05
PriceTypeCode == 6  \* 0x06
PegOffsetCode == 7  \* 0x07
DiscretionPriceCode == 9  \* 0x09
DiscretionPriceTypeCode == 10  \* 0x0a
DiscretionPegOffsetCode == 11  \* 0x0b
PostOnlyCode == 12  \* 0x0c
RandomReservesCode == 13  \* 0x0d
RouteCode == 14  \* 0x0e
ExpireTimeCode == 15  \* 0x0f
TradeNowCode == 16  \* 0x10
HandleInstCode == 17  \* 0x11
BboWeightIndicatorCode == 18  \* 0x12
GroupIdCode == 24  \* 0x18
SharesLocatedCode == 25  \* 0x19
UserRefIdxCode == 28  \* 0x1c
AiqStrategyCode == 29  \* 0x1d
AiqGroupIdCode == 30  \* 0x1e

OrderAcceptedOptionalValue ==
    [ tag : {FirmCode}, body : Firm ]
        \cup [ tag : {MinQtyCode}, body : MinQty ]
        \cup [ tag : {CustomerTypeCode}, body : CustomerType ]
        \cup [ tag : {MaxFloorCode}, body : MaxFloor ]
        \cup [ tag : {PriceTypeCode}, body : PriceType ]
        \cup [ tag : {PegOffsetCode}, body : PegOffset ]
        \cup [ tag : {DiscretionPriceCode}, body : DiscretionPrice ]
        \cup [ tag : {DiscretionPriceTypeCode}, body : DiscretionPriceType ]
        \cup [ tag : {DiscretionPegOffsetCode}, body : DiscretionPegOffset ]
        \cup [ tag : {PostOnlyCode}, body : PostOnly ]
        \cup [ tag : {RandomReservesCode}, body : RandomReserves ]
        \cup [ tag : {RouteCode}, body : Route ]
        \cup [ tag : {ExpireTimeCode}, body : ExpireTime ]
        \cup [ tag : {TradeNowCode}, body : TradeNow ]
        \cup [ tag : {HandleInstCode}, body : HandleInst ]
        \cup [ tag : {BboWeightIndicatorCode}, body : BboWeightIndicator ]
        \cup [ tag : {GroupIdCode}, body : GroupId ]
        \cup [ tag : {SharesLocatedCode}, body : SharesLocated ]
        \cup [ tag : {UserRefIdxCode}, body : UserRefIdx ]
        \cup [ tag : {AiqStrategyCode}, body : AiqStrategy ]
        \cup [ tag : {AiqGroupIdCode}, body : AiqGroupId ]

EncodeOrderAcceptedOptionalValue(message) ==
    CASE message.tag = FirmCode -> EncodeFirm(message.body)
      [] message.tag = MinQtyCode -> EncodeMinQty(message.body)
      [] message.tag = CustomerTypeCode -> EncodeCustomerType(message.body)
      [] message.tag = MaxFloorCode -> EncodeMaxFloor(message.body)
      [] message.tag = PriceTypeCode -> EncodePriceType(message.body)
      [] message.tag = PegOffsetCode -> EncodePegOffset(message.body)
      [] message.tag = DiscretionPriceCode -> EncodeDiscretionPrice(message.body)
      [] message.tag = DiscretionPriceTypeCode -> EncodeDiscretionPriceType(message.body)
      [] message.tag = DiscretionPegOffsetCode -> EncodeDiscretionPegOffset(message.body)
      [] message.tag = PostOnlyCode -> EncodePostOnly(message.body)
      [] message.tag = RandomReservesCode -> EncodeRandomReserves(message.body)
      [] message.tag = RouteCode -> EncodeRoute(message.body)
      [] message.tag = ExpireTimeCode -> EncodeExpireTime(message.body)
      [] message.tag = TradeNowCode -> EncodeTradeNow(message.body)
      [] message.tag = HandleInstCode -> EncodeHandleInst(message.body)
      [] message.tag = BboWeightIndicatorCode -> EncodeBboWeightIndicator(message.body)
      [] message.tag = GroupIdCode -> EncodeGroupId(message.body)
      [] message.tag = SharesLocatedCode -> EncodeSharesLocated(message.body)
      [] message.tag = UserRefIdxCode -> EncodeUserRefIdx(message.body)
      [] message.tag = AiqStrategyCode -> EncodeAiqStrategy(message.body)
      [] message.tag = AiqGroupIdCode -> EncodeAiqGroupId(message.body)

DecodeOrderAcceptedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = FirmCode -> DecodeFirm(bytes)
              [] tag = MinQtyCode -> DecodeMinQty(bytes)
              [] tag = CustomerTypeCode -> DecodeCustomerType(bytes)
              [] tag = MaxFloorCode -> DecodeMaxFloor(bytes)
              [] tag = PriceTypeCode -> DecodePriceType(bytes)
              [] tag = PegOffsetCode -> DecodePegOffset(bytes)
              [] tag = DiscretionPriceCode -> DecodeDiscretionPrice(bytes)
              [] tag = DiscretionPriceTypeCode -> DecodeDiscretionPriceType(bytes)
              [] tag = DiscretionPegOffsetCode -> DecodeDiscretionPegOffset(bytes)
              [] tag = PostOnlyCode -> DecodePostOnly(bytes)
              [] tag = RandomReservesCode -> DecodeRandomReserves(bytes)
              [] tag = RouteCode -> DecodeRoute(bytes)
              [] tag = ExpireTimeCode -> DecodeExpireTime(bytes)
              [] tag = TradeNowCode -> DecodeTradeNow(bytes)
              [] tag = HandleInstCode -> DecodeHandleInst(bytes)
              [] tag = BboWeightIndicatorCode -> DecodeBboWeightIndicator(bytes)
              [] tag = GroupIdCode -> DecodeGroupId(bytes)
              [] tag = SharesLocatedCode -> DecodeSharesLocated(bytes)
              [] tag = UserRefIdxCode -> DecodeUserRefIdx(bytes)
              [] tag = AiqStrategyCode -> DecodeAiqStrategy(bytes)
              [] tag = AiqGroupIdCode -> DecodeAiqGroupId(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderAcceptedOptionalValue == [tag |-> FirmCode, body |-> ZeroFirm]

(* Each Order Accepted Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderAcceptedOptionalValue ==
    { [tag |-> FirmCode, body |-> one] : one \in CheckedFirm }
        \cup { [tag |-> MinQtyCode, body |-> one] : one \in CheckedMinQty }
        \cup { [tag |-> CustomerTypeCode, body |-> one] : one \in CheckedCustomerType }
        \cup { [tag |-> MaxFloorCode, body |-> one] : one \in CheckedMaxFloor }
        \cup { [tag |-> PriceTypeCode, body |-> one] : one \in CheckedPriceType }
        \cup { [tag |-> PegOffsetCode, body |-> one] : one \in CheckedPegOffset }
        \cup { [tag |-> DiscretionPriceCode, body |-> one] : one \in CheckedDiscretionPrice }
        \cup { [tag |-> DiscretionPriceTypeCode, body |-> one] : one \in CheckedDiscretionPriceType }
        \cup { [tag |-> DiscretionPegOffsetCode, body |-> one] : one \in CheckedDiscretionPegOffset }
        \cup { [tag |-> PostOnlyCode, body |-> one] : one \in CheckedPostOnly }
        \cup { [tag |-> RandomReservesCode, body |-> one] : one \in CheckedRandomReserves }
        \cup { [tag |-> RouteCode, body |-> one] : one \in CheckedRoute }
        \cup { [tag |-> ExpireTimeCode, body |-> one] : one \in CheckedExpireTime }
        \cup { [tag |-> TradeNowCode, body |-> one] : one \in CheckedTradeNow }
        \cup { [tag |-> HandleInstCode, body |-> one] : one \in CheckedHandleInst }
        \cup { [tag |-> BboWeightIndicatorCode, body |-> one] : one \in CheckedBboWeightIndicator }
        \cup { [tag |-> GroupIdCode, body |-> one] : one \in CheckedGroupId }
        \cup { [tag |-> SharesLocatedCode, body |-> one] : one \in CheckedSharesLocated }
        \cup { [tag |-> UserRefIdxCode, body |-> one] : one \in CheckedUserRefIdx }
        \cup { [tag |-> AiqStrategyCode, body |-> one] : one \in CheckedAiqStrategy }
        \cup { [tag |-> AiqGroupIdCode, body |-> one] : one \in CheckedAiqGroupId }

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
    { [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> FirmCode, body |-> ZeroFirm]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> MinQtyCode, body |-> ZeroMinQty]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> CustomerTypeCode, body |-> ZeroCustomerType]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> MaxFloorCode, body |-> ZeroMaxFloor]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> PriceTypeCode, body |-> ZeroPriceType]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> PegOffsetCode, body |-> ZeroPegOffset]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> DiscretionPriceCode, body |-> ZeroDiscretionPrice]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> DiscretionPriceTypeCode, body |-> ZeroDiscretionPriceType]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> DiscretionPegOffsetCode, body |-> ZeroDiscretionPegOffset]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> PostOnlyCode, body |-> ZeroPostOnly]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> RandomReservesCode, body |-> ZeroRandomReserves]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> RouteCode, body |-> ZeroRoute]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> ExpireTimeCode, body |-> ZeroExpireTime]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> TradeNowCode, body |-> ZeroTradeNow]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> HandleInstCode, body |-> ZeroHandleInst]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> BboWeightIndicatorCode, body |-> ZeroBboWeightIndicator]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> GroupIdCode, body |-> ZeroGroupId]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> SharesLocatedCode, body |-> ZeroSharesLocated]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> UserRefIdxCode, body |-> ZeroUserRefIdx]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> AiqStrategyCode, body |-> ZeroAiqStrategy]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> AiqGroupIdCode, body |-> ZeroAiqGroupId]] }

(***************************************************************************)
(* Order Accepted Message                                                  *)
(***************************************************************************)

OrderAcceptedMessage ==
    [ timestamp                   : Sample(8),
      userRefNum                  : Sample(4),
      side                        : Sample(1),
      quantity                    : Sample(4),
      symbol                      : Sample(8),
      price                       : Sample(8),
      timeInForce                 : Sample(1),
      display                     : Sample(1),
      orderReferenceNumber        : Sample(8),
      capacity                    : Sample(1),
      interMarketSweepEligibility : Sample(1),
      crossType                   : Sample(1),
      orderState                  : Sample(1),
      clordid                     : Sample(14),
      orderAcceptedAppendage      : SampleLists(OneOrderAcceptedAppendage) ]

EncodeOrderAcceptedMessage(message) ==
    LET payload == EncodeOrderAcceptedAppendageList(message.orderAcceptedAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.side
            \o message.quantity
            \o message.symbol
            \o message.price
            \o message.timeInForce
            \o message.display
            \o message.orderReferenceNumber
            \o message.capacity
            \o message.interMarketSweepEligibility
            \o message.crossType
            \o message.orderState
            \o message.clordid
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderAcceptedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET side == ReadBytes(userRefNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET display == ReadBytes(timeInForce.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(display.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET capacity == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET interMarketSweepEligibility == ReadBytes(capacity.rest, 1) IN IF ~interMarketSweepEligibility.ok THEN Fail ELSE
    LET crossType == ReadBytes(interMarketSweepEligibility.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET orderState == ReadBytes(crossType.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderState.rest, 14) IN IF ~clordid.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(clordid.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        orderAcceptedAppendage == ReadOrderAcceptedAppendageAll(framed)
    IN  IF ~orderAcceptedAppendage.ok \/ orderAcceptedAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         userRefNum                  |-> userRefNum.value,
         side                        |-> side.value,
         quantity                    |-> quantity.value,
         symbol                      |-> symbol.value,
         price                       |-> price.value,
         timeInForce                 |-> timeInForce.value,
         display                     |-> display.value,
         orderReferenceNumber        |-> orderReferenceNumber.value,
         capacity                    |-> capacity.value,
         interMarketSweepEligibility |-> interMarketSweepEligibility.value,
         crossType                   |-> crossType.value,
         orderState                  |-> orderState.value,
         clordid                     |-> clordid.value,
         orderAcceptedAppendage      |-> orderAcceptedAppendage.value ], beyond)

ZeroOrderAcceptedMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      userRefNum                  |-> [i \in 1 .. 4 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      quantity                    |-> [i \in 1 .. 4 |-> 0],
      symbol                      |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      display                     |-> [i \in 1 .. 1 |-> 0],
      orderReferenceNumber        |-> [i \in 1 .. 8 |-> 0],
      capacity                    |-> [i \in 1 .. 1 |-> 0],
      interMarketSweepEligibility |-> [i \in 1 .. 1 |-> 0],
      crossType                   |-> [i \in 1 .. 1 |-> 0],
      orderState                  |-> [i \in 1 .. 1 |-> 0],
      clordid                     |-> [i \in 1 .. 14 |-> 0],
      orderAcceptedAppendage      |-> << >> ]

(* Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcceptedMessage ==
    { ZeroOrderAcceptedMessage }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.interMarketSweepEligibility = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.clordid = one] : one \in Sample(14) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderAcceptedAppendage = one] : one \in SampleLists(OneOrderAcceptedAppendage) }

(***************************************************************************)
(* Firm: 4 bytes                                                           *)
(***************************************************************************)

Firm2 ==
    [ firm : Sample(4) ]

EncodeFirm2(message) ==
    message.firm

DecodeFirm2(bytes) ==
    LET firm == ReadBytes(bytes, 4) IN IF ~firm.ok THEN Fail ELSE
    Ok([ firm |-> firm.value ], firm.rest)

ZeroFirm2 ==
    [ firm |-> [i \in 1 .. 4 |-> 0] ]

(* Firm at zero, then each field in turn at the values it is checked at *)
CheckedFirm2 ==
    { ZeroFirm2 }
        \cup { [ZeroFirm2 EXCEPT !.firm = one] : one \in Sample(4) }

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
(* Price Type: 1 bytes                                                     *)
(***************************************************************************)

PriceType2 ==
    [ priceType : Sample(1) ]

EncodePriceType2(message) ==
    message.priceType

DecodePriceType2(bytes) ==
    LET priceType == ReadBytes(bytes, 1) IN IF ~priceType.ok THEN Fail ELSE
    Ok([ priceType |-> priceType.value ], priceType.rest)

ZeroPriceType2 ==
    [ priceType |-> [i \in 1 .. 1 |-> 0] ]

(* Price Type at zero, then each field in turn at the values it is checked at *)
CheckedPriceType2 ==
    { ZeroPriceType2 }
        \cup { [ZeroPriceType2 EXCEPT !.priceType = one] : one \in Sample(1) }

(***************************************************************************)
(* Post Only: 1 bytes                                                      *)
(***************************************************************************)

PostOnly2 ==
    [ postOnly : Sample(1) ]

EncodePostOnly2(message) ==
    message.postOnly

DecodePostOnly2(bytes) ==
    LET postOnly == ReadBytes(bytes, 1) IN IF ~postOnly.ok THEN Fail ELSE
    Ok([ postOnly |-> postOnly.value ], postOnly.rest)

ZeroPostOnly2 ==
    [ postOnly |-> [i \in 1 .. 1 |-> 0] ]

(* Post Only at zero, then each field in turn at the values it is checked at *)
CheckedPostOnly2 ==
    { ZeroPostOnly2 }
        \cup { [ZeroPostOnly2 EXCEPT !.postOnly = one] : one \in Sample(1) }

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
(* Trade Now: 1 bytes                                                      *)
(***************************************************************************)

TradeNow2 ==
    [ tradeNow : Sample(1) ]

EncodeTradeNow2(message) ==
    message.tradeNow

DecodeTradeNow2(bytes) ==
    LET tradeNow == ReadBytes(bytes, 1) IN IF ~tradeNow.ok THEN Fail ELSE
    Ok([ tradeNow |-> tradeNow.value ], tradeNow.rest)

ZeroTradeNow2 ==
    [ tradeNow |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Now at zero, then each field in turn at the values it is checked at *)
CheckedTradeNow2 ==
    { ZeroTradeNow2 }
        \cup { [ZeroTradeNow2 EXCEPT !.tradeNow = one] : one \in Sample(1) }

(***************************************************************************)
(* Handle Inst: 1 bytes                                                    *)
(***************************************************************************)

HandleInst2 ==
    [ handleInst : Sample(1) ]

EncodeHandleInst2(message) ==
    message.handleInst

DecodeHandleInst2(bytes) ==
    LET handleInst == ReadBytes(bytes, 1) IN IF ~handleInst.ok THEN Fail ELSE
    Ok([ handleInst |-> handleInst.value ], handleInst.rest)

ZeroHandleInst2 ==
    [ handleInst |-> [i \in 1 .. 1 |-> 0] ]

(* Handle Inst at zero, then each field in turn at the values it is checked at *)
CheckedHandleInst2 ==
    { ZeroHandleInst2 }
        \cup { [ZeroHandleInst2 EXCEPT !.handleInst = one] : one \in Sample(1) }

(***************************************************************************)
(* Bbo Weight Indicator: 1 bytes                                           *)
(***************************************************************************)

BboWeightIndicator2 ==
    [ bboWeightIndicator : Sample(1) ]

EncodeBboWeightIndicator2(message) ==
    message.bboWeightIndicator

DecodeBboWeightIndicator2(bytes) ==
    LET bboWeightIndicator == ReadBytes(bytes, 1) IN IF ~bboWeightIndicator.ok THEN Fail ELSE
    Ok([ bboWeightIndicator |-> bboWeightIndicator.value ], bboWeightIndicator.rest)

ZeroBboWeightIndicator2 ==
    [ bboWeightIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Bbo Weight Indicator at zero, then each field in turn at the values it is checked at *)
CheckedBboWeightIndicator2 ==
    { ZeroBboWeightIndicator2 }
        \cup { [ZeroBboWeightIndicator2 EXCEPT !.bboWeightIndicator = one] : one \in Sample(1) }

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
(* Aiq Strategy: 1 bytes                                                   *)
(***************************************************************************)

AiqStrategy2 ==
    [ aiqStrategy : Sample(1) ]

EncodeAiqStrategy2(message) ==
    message.aiqStrategy

DecodeAiqStrategy2(bytes) ==
    LET aiqStrategy == ReadBytes(bytes, 1) IN IF ~aiqStrategy.ok THEN Fail ELSE
    Ok([ aiqStrategy |-> aiqStrategy.value ], aiqStrategy.rest)

ZeroAiqStrategy2 ==
    [ aiqStrategy |-> [i \in 1 .. 1 |-> 0] ]

(* Aiq Strategy at zero, then each field in turn at the values it is checked at *)
CheckedAiqStrategy2 ==
    { ZeroAiqStrategy2 }
        \cup { [ZeroAiqStrategy2 EXCEPT !.aiqStrategy = one] : one \in Sample(1) }

(***************************************************************************)
(* Aiq Group Id: 2 bytes                                                   *)
(***************************************************************************)

AiqGroupId2 ==
    [ aiqGroupId : Sample(2) ]

EncodeAiqGroupId2(message) ==
    message.aiqGroupId

DecodeAiqGroupId2(bytes) ==
    LET aiqGroupId == ReadBytes(bytes, 2) IN IF ~aiqGroupId.ok THEN Fail ELSE
    Ok([ aiqGroupId |-> aiqGroupId.value ], aiqGroupId.rest)

ZeroAiqGroupId2 ==
    [ aiqGroupId |-> [i \in 1 .. 2 |-> 0] ]

(* Aiq Group Id at zero, then each field in turn at the values it is checked at *)
CheckedAiqGroupId2 ==
    { ZeroAiqGroupId2 }
        \cup { [ZeroAiqGroupId2 EXCEPT !.aiqGroupId = one] : one \in Sample(2) }

(***************************************************************************)
(* Replaced Message Optional Value, selected by Replaced Message Optional  *)
(* Field                                                                   *)
(***************************************************************************)

FirmCode2 == 2  \* 0x02
MinQtyCode2 == 3  \* 0x03
MaxFloorCode2 == 5  \* 0x05
PriceTypeCode2 == 6  \* 0x06
PostOnlyCode2 == 12  \* 0x0c
ExpireTimeCode2 == 15  \* 0x0f
TradeNowCode2 == 16  \* 0x10
HandleInstCode2 == 17  \* 0x11
BboWeightIndicatorCode2 == 18  \* 0x12
UserRefIdxCode2 == 28  \* 0x1c
AiqStrategyCode2 == 29  \* 0x1d
AiqGroupIdCode2 == 30  \* 0x1e

ReplacedMessageOptionalValue ==
    [ tag : {FirmCode2}, body : Firm2 ]
        \cup [ tag : {MinQtyCode2}, body : MinQty2 ]
        \cup [ tag : {MaxFloorCode2}, body : MaxFloor2 ]
        \cup [ tag : {PriceTypeCode2}, body : PriceType2 ]
        \cup [ tag : {PostOnlyCode2}, body : PostOnly2 ]
        \cup [ tag : {ExpireTimeCode2}, body : ExpireTime2 ]
        \cup [ tag : {TradeNowCode2}, body : TradeNow2 ]
        \cup [ tag : {HandleInstCode2}, body : HandleInst2 ]
        \cup [ tag : {BboWeightIndicatorCode2}, body : BboWeightIndicator2 ]
        \cup [ tag : {UserRefIdxCode2}, body : UserRefIdx2 ]
        \cup [ tag : {AiqStrategyCode2}, body : AiqStrategy2 ]
        \cup [ tag : {AiqGroupIdCode2}, body : AiqGroupId2 ]

EncodeReplacedMessageOptionalValue(message) ==
    CASE message.tag = FirmCode2 -> EncodeFirm2(message.body)
      [] message.tag = MinQtyCode2 -> EncodeMinQty2(message.body)
      [] message.tag = MaxFloorCode2 -> EncodeMaxFloor2(message.body)
      [] message.tag = PriceTypeCode2 -> EncodePriceType2(message.body)
      [] message.tag = PostOnlyCode2 -> EncodePostOnly2(message.body)
      [] message.tag = ExpireTimeCode2 -> EncodeExpireTime2(message.body)
      [] message.tag = TradeNowCode2 -> EncodeTradeNow2(message.body)
      [] message.tag = HandleInstCode2 -> EncodeHandleInst2(message.body)
      [] message.tag = BboWeightIndicatorCode2 -> EncodeBboWeightIndicator2(message.body)
      [] message.tag = UserRefIdxCode2 -> EncodeUserRefIdx2(message.body)
      [] message.tag = AiqStrategyCode2 -> EncodeAiqStrategy2(message.body)
      [] message.tag = AiqGroupIdCode2 -> EncodeAiqGroupId2(message.body)

DecodeReplacedMessageOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = FirmCode2 -> DecodeFirm2(bytes)
              [] tag = MinQtyCode2 -> DecodeMinQty2(bytes)
              [] tag = MaxFloorCode2 -> DecodeMaxFloor2(bytes)
              [] tag = PriceTypeCode2 -> DecodePriceType2(bytes)
              [] tag = PostOnlyCode2 -> DecodePostOnly2(bytes)
              [] tag = ExpireTimeCode2 -> DecodeExpireTime2(bytes)
              [] tag = TradeNowCode2 -> DecodeTradeNow2(bytes)
              [] tag = HandleInstCode2 -> DecodeHandleInst2(bytes)
              [] tag = BboWeightIndicatorCode2 -> DecodeBboWeightIndicator2(bytes)
              [] tag = UserRefIdxCode2 -> DecodeUserRefIdx2(bytes)
              [] tag = AiqStrategyCode2 -> DecodeAiqStrategy2(bytes)
              [] tag = AiqGroupIdCode2 -> DecodeAiqGroupId2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroReplacedMessageOptionalValue == [tag |-> FirmCode2, body |-> ZeroFirm2]

(* Each Replaced Message Optional Value in turn, at the values the message it names is checked at *)
CheckedReplacedMessageOptionalValue ==
    { [tag |-> FirmCode2, body |-> one] : one \in CheckedFirm2 }
        \cup { [tag |-> MinQtyCode2, body |-> one] : one \in CheckedMinQty2 }
        \cup { [tag |-> MaxFloorCode2, body |-> one] : one \in CheckedMaxFloor2 }
        \cup { [tag |-> PriceTypeCode2, body |-> one] : one \in CheckedPriceType2 }
        \cup { [tag |-> PostOnlyCode2, body |-> one] : one \in CheckedPostOnly2 }
        \cup { [tag |-> ExpireTimeCode2, body |-> one] : one \in CheckedExpireTime2 }
        \cup { [tag |-> TradeNowCode2, body |-> one] : one \in CheckedTradeNow2 }
        \cup { [tag |-> HandleInstCode2, body |-> one] : one \in CheckedHandleInst2 }
        \cup { [tag |-> BboWeightIndicatorCode2, body |-> one] : one \in CheckedBboWeightIndicator2 }
        \cup { [tag |-> UserRefIdxCode2, body |-> one] : one \in CheckedUserRefIdx2 }
        \cup { [tag |-> AiqStrategyCode2, body |-> one] : one \in CheckedAiqStrategy2 }
        \cup { [tag |-> AiqGroupIdCode2, body |-> one] : one \in CheckedAiqGroupId2 }

(***************************************************************************)
(* Replaced Message Appendage, framed by Optional Field Length             *)
(***************************************************************************)

ReplacedMessageAppendage ==
    [ replacedMessageOptionalValue : ReplacedMessageOptionalValue ]

EncodeReplacedMessageAppendageBody(message) ==
    EncodeUIntBE(message.replacedMessageOptionalValue.tag, 1)
        \o EncodeReplacedMessageOptionalValue(message.replacedMessageOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeReplacedMessageAppendage(message) ==
    LET body == EncodeReplacedMessageAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeReplacedMessageAppendageBody(bytes) ==
    LET replacedMessageOptionalField == ReadUIntBE(bytes, 1) IN IF ~replacedMessageOptionalField.ok THEN Fail ELSE
    LET replacedMessageOptionalValue == DecodeReplacedMessageOptionalValue(replacedMessageOptionalField.value, replacedMessageOptionalField.rest) IN IF ~replacedMessageOptionalValue.ok THEN Fail ELSE
    Ok([ replacedMessageOptionalValue |-> replacedMessageOptionalValue.value ], replacedMessageOptionalValue.rest)

DecodeReplacedMessageAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeReplacedMessageAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroReplacedMessageAppendage ==
    [ replacedMessageOptionalValue |-> ZeroReplacedMessageOptionalValue ]

(* Replaced Message Appendage at zero, then each field in turn at the values it is checked at *)
CheckedReplacedMessageAppendage ==
    { ZeroReplacedMessageAppendage }
        \cup { [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = one] : one \in CheckedReplacedMessageOptionalValue }

(* A run of Replaced Message Appendage, written one after another *)
RECURSIVE EncodeReplacedMessageAppendageList(_)
EncodeReplacedMessageAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeReplacedMessageAppendage(Head(messages)) \o EncodeReplacedMessageAppendageList(Tail(messages))

(* As many Replaced Message Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadReplacedMessageAppendageAll(_)
ReadReplacedMessageAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeReplacedMessageAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadReplacedMessageAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Replaced Message Appendage of each kind, for the lists that carry them *)
OneReplacedMessageAppendage ==
    { [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> FirmCode2, body |-> ZeroFirm2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> MinQtyCode2, body |-> ZeroMinQty2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> MaxFloorCode2, body |-> ZeroMaxFloor2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> PriceTypeCode2, body |-> ZeroPriceType2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> PostOnlyCode2, body |-> ZeroPostOnly2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> ExpireTimeCode2, body |-> ZeroExpireTime2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> TradeNowCode2, body |-> ZeroTradeNow2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> HandleInstCode2, body |-> ZeroHandleInst2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> BboWeightIndicatorCode2, body |-> ZeroBboWeightIndicator2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> UserRefIdxCode2, body |-> ZeroUserRefIdx2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> AiqStrategyCode2, body |-> ZeroAiqStrategy2]],
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> AiqGroupIdCode2, body |-> ZeroAiqGroupId2]] }

(***************************************************************************)
(* Replaced Message                                                        *)
(***************************************************************************)

ReplacedMessage ==
    [ timestamp                   : Sample(8),
      origUserRefNum              : Sample(4),
      userRefNum                  : Sample(4),
      side                        : Sample(1),
      quantity                    : Sample(4),
      symbol                      : Sample(8),
      price                       : Sample(8),
      timeInForce                 : Sample(1),
      display                     : Sample(1),
      orderReferenceNumber        : Sample(8),
      capacity                    : Sample(1),
      interMarketSweepEligibility : Sample(1),
      crossType                   : Sample(1),
      orderState                  : Sample(1),
      clordid                     : Sample(14),
      replacedMessageAppendage    : SampleLists(OneReplacedMessageAppendage) ]

EncodeReplacedMessage(message) ==
    LET payload == EncodeReplacedMessageAppendageList(message.replacedMessageAppendage)
    IN  message.timestamp
            \o message.origUserRefNum
            \o message.userRefNum
            \o message.side
            \o message.quantity
            \o message.symbol
            \o message.price
            \o message.timeInForce
            \o message.display
            \o message.orderReferenceNumber
            \o message.capacity
            \o message.interMarketSweepEligibility
            \o message.crossType
            \o message.orderState
            \o message.clordid
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeReplacedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET origUserRefNum == ReadBytes(timestamp.rest, 4) IN IF ~origUserRefNum.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(origUserRefNum.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET side == ReadBytes(userRefNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET display == ReadBytes(timeInForce.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(display.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET capacity == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET interMarketSweepEligibility == ReadBytes(capacity.rest, 1) IN IF ~interMarketSweepEligibility.ok THEN Fail ELSE
    LET crossType == ReadBytes(interMarketSweepEligibility.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET orderState == ReadBytes(crossType.rest, 1) IN IF ~orderState.ok THEN Fail ELSE
    LET clordid == ReadBytes(orderState.rest, 14) IN IF ~clordid.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(clordid.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        replacedMessageAppendage == ReadReplacedMessageAppendageAll(framed)
    IN  IF ~replacedMessageAppendage.ok \/ replacedMessageAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         origUserRefNum              |-> origUserRefNum.value,
         userRefNum                  |-> userRefNum.value,
         side                        |-> side.value,
         quantity                    |-> quantity.value,
         symbol                      |-> symbol.value,
         price                       |-> price.value,
         timeInForce                 |-> timeInForce.value,
         display                     |-> display.value,
         orderReferenceNumber        |-> orderReferenceNumber.value,
         capacity                    |-> capacity.value,
         interMarketSweepEligibility |-> interMarketSweepEligibility.value,
         crossType                   |-> crossType.value,
         orderState                  |-> orderState.value,
         clordid                     |-> clordid.value,
         replacedMessageAppendage    |-> replacedMessageAppendage.value ], beyond)

ZeroReplacedMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      origUserRefNum              |-> [i \in 1 .. 4 |-> 0],
      userRefNum                  |-> [i \in 1 .. 4 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      quantity                    |-> [i \in 1 .. 4 |-> 0],
      symbol                      |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      display                     |-> [i \in 1 .. 1 |-> 0],
      orderReferenceNumber        |-> [i \in 1 .. 8 |-> 0],
      capacity                    |-> [i \in 1 .. 1 |-> 0],
      interMarketSweepEligibility |-> [i \in 1 .. 1 |-> 0],
      crossType                   |-> [i \in 1 .. 1 |-> 0],
      orderState                  |-> [i \in 1 .. 1 |-> 0],
      clordid                     |-> [i \in 1 .. 14 |-> 0],
      replacedMessageAppendage    |-> << >> ]

(* Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedReplacedMessage ==
    { ZeroReplacedMessage }
        \cup { [ZeroReplacedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroReplacedMessage EXCEPT !.origUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplacedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplacedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroReplacedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroReplacedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroReplacedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReplacedMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroReplacedMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroReplacedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroReplacedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroReplacedMessage EXCEPT !.interMarketSweepEligibility = one] : one \in Sample(1) }
        \cup { [ZeroReplacedMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroReplacedMessage EXCEPT !.orderState = one] : one \in Sample(1) }
        \cup { [ZeroReplacedMessage EXCEPT !.clordid = one] : one \in Sample(14) }
        \cup { [ZeroReplacedMessage EXCEPT !.replacedMessageAppendage = one] : one \in SampleLists(OneReplacedMessageAppendage) }

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
(* Canceled Message Optional Value, selected by Canceled Message Optional  *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode3 == 28  \* 0x1c

CanceledMessageOptionalValue ==
    [ tag : {UserRefIdxCode3}, body : UserRefIdx3 ]

EncodeCanceledMessageOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode3 -> EncodeUserRefIdx3(message.body)

DecodeCanceledMessageOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode3 -> DecodeUserRefIdx3(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCanceledMessageOptionalValue == [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]

(* Each Canceled Message Optional Value in turn, at the values the message it names is checked at *)
CheckedCanceledMessageOptionalValue ==
    { [tag |-> UserRefIdxCode3, body |-> one] : one \in CheckedUserRefIdx3 }

(***************************************************************************)
(* Canceled Message Appendage, framed by Optional Field Length             *)
(***************************************************************************)

CanceledMessageAppendage ==
    [ canceledMessageOptionalValue : CanceledMessageOptionalValue ]

EncodeCanceledMessageAppendageBody(message) ==
    EncodeUIntBE(message.canceledMessageOptionalValue.tag, 1)
        \o EncodeCanceledMessageOptionalValue(message.canceledMessageOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeCanceledMessageAppendage(message) ==
    LET body == EncodeCanceledMessageAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeCanceledMessageAppendageBody(bytes) ==
    LET canceledMessageOptionalField == ReadUIntBE(bytes, 1) IN IF ~canceledMessageOptionalField.ok THEN Fail ELSE
    LET canceledMessageOptionalValue == DecodeCanceledMessageOptionalValue(canceledMessageOptionalField.value, canceledMessageOptionalField.rest) IN IF ~canceledMessageOptionalValue.ok THEN Fail ELSE
    Ok([ canceledMessageOptionalValue |-> canceledMessageOptionalValue.value ], canceledMessageOptionalValue.rest)

DecodeCanceledMessageAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeCanceledMessageAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroCanceledMessageAppendage ==
    [ canceledMessageOptionalValue |-> ZeroCanceledMessageOptionalValue ]

(* Canceled Message Appendage at zero, then each field in turn at the values it is checked at *)
CheckedCanceledMessageAppendage ==
    { ZeroCanceledMessageAppendage }
        \cup { [ZeroCanceledMessageAppendage EXCEPT !.canceledMessageOptionalValue = one] : one \in CheckedCanceledMessageOptionalValue }

(* A run of Canceled Message Appendage, written one after another *)
RECURSIVE EncodeCanceledMessageAppendageList(_)
EncodeCanceledMessageAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCanceledMessageAppendage(Head(messages)) \o EncodeCanceledMessageAppendageList(Tail(messages))

(* As many Canceled Message Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadCanceledMessageAppendageAll(_)
ReadCanceledMessageAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeCanceledMessageAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCanceledMessageAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Canceled Message Appendage of each kind, for the lists that carry them *)
OneCanceledMessageAppendage ==
    { [ZeroCanceledMessageAppendage EXCEPT !.canceledMessageOptionalValue = [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]] }

(***************************************************************************)
(* Canceled Message                                                        *)
(***************************************************************************)

CanceledMessageTail ==
    [ canceledMessageAppendage : SampleLists(OneCanceledMessageAppendage) ]

EncodeCanceledMessageTail(message) ==
    LET payload == EncodeCanceledMessageAppendageList(message.canceledMessageAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeCanceledMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        canceledMessageAppendage == ReadCanceledMessageAppendageAll(framed)
    IN  IF ~canceledMessageAppendage.ok \/ canceledMessageAppendage.rest # << >> THEN Fail ELSE
    Ok([ canceledMessageAppendage |-> canceledMessageAppendage.value ], beyond)

ZeroCanceledMessageTail ==
    [ canceledMessageAppendage |-> << >> ]

(* Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedCanceledMessageTail ==
    { ZeroCanceledMessageTail }
        \cup { [ZeroCanceledMessageTail EXCEPT !.canceledMessageAppendage = one] : one \in SampleLists(OneCanceledMessageAppendage) }

(* Canceled Message runs on only when bytes remain, so it is there or it is not *)
WithoutCanceledMessageTail == [there |-> FALSE, value |-> ZeroCanceledMessageTail]

MaybeCanceledMessageTail ==
    { WithoutCanceledMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedCanceledMessageTail }

ReadCanceledMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutCanceledMessageTail, << >>)
    ELSE LET one == DecodeCanceledMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Canceled Message                                                        *)
(***************************************************************************)

CanceledMessage ==
    [ timestamp           : Sample(8),
      userRefNum          : Sample(4),
      quantity            : Sample(4),
      cancelOrderReason   : Sample(1),
      canceledMessageTail : MaybeCanceledMessageTail ]

EncodeCanceledMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.quantity
        \o message.cancelOrderReason
        \o IF message.canceledMessageTail.there THEN EncodeCanceledMessageTail(message.canceledMessageTail.value) ELSE << >>

DecodeCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(userRefNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET cancelOrderReason == ReadBytes(quantity.rest, 1) IN IF ~cancelOrderReason.ok THEN Fail ELSE
    LET canceledMessageTail == ReadCanceledMessageTailMaybe(cancelOrderReason.rest) IN IF ~canceledMessageTail.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         userRefNum          |-> userRefNum.value,
         quantity            |-> quantity.value,
         cancelOrderReason   |-> cancelOrderReason.value,
         canceledMessageTail |-> canceledMessageTail.value ], canceledMessageTail.rest)

ZeroCanceledMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      userRefNum          |-> [i \in 1 .. 4 |-> 0],
      quantity            |-> [i \in 1 .. 4 |-> 0],
      cancelOrderReason   |-> [i \in 1 .. 1 |-> 0],
      canceledMessageTail |-> WithoutCanceledMessageTail ]

(* Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedCanceledMessage ==
    { ZeroCanceledMessage }
        \cup { [ZeroCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCanceledMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCanceledMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroCanceledMessage EXCEPT !.cancelOrderReason = one] : one \in Sample(1) }
        \cup { [ZeroCanceledMessage EXCEPT !.canceledMessageTail = one] : one \in MaybeCanceledMessageTail }

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
(* Aiq Canceled Optional Value, selected by Aiq Canceled Optional Field    *)
(***************************************************************************)

UserRefIdxCode4 == 28  \* 0x1c

AiqCanceledOptionalValue ==
    [ tag : {UserRefIdxCode4}, body : UserRefIdx4 ]

EncodeAiqCanceledOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode4 -> EncodeUserRefIdx4(message.body)

DecodeAiqCanceledOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode4 -> DecodeUserRefIdx4(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAiqCanceledOptionalValue == [tag |-> UserRefIdxCode4, body |-> ZeroUserRefIdx4]

(* Each Aiq Canceled Optional Value in turn, at the values the message it names is checked at *)
CheckedAiqCanceledOptionalValue ==
    { [tag |-> UserRefIdxCode4, body |-> one] : one \in CheckedUserRefIdx4 }

(***************************************************************************)
(* Aiq Canceled Appendage, framed by Optional Field Length                 *)
(***************************************************************************)

AiqCanceledAppendage ==
    [ aiqCanceledOptionalValue : AiqCanceledOptionalValue ]

EncodeAiqCanceledAppendageBody(message) ==
    EncodeUIntBE(message.aiqCanceledOptionalValue.tag, 1)
        \o EncodeAiqCanceledOptionalValue(message.aiqCanceledOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeAiqCanceledAppendage(message) ==
    LET body == EncodeAiqCanceledAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeAiqCanceledAppendageBody(bytes) ==
    LET aiqCanceledOptionalField == ReadUIntBE(bytes, 1) IN IF ~aiqCanceledOptionalField.ok THEN Fail ELSE
    LET aiqCanceledOptionalValue == DecodeAiqCanceledOptionalValue(aiqCanceledOptionalField.value, aiqCanceledOptionalField.rest) IN IF ~aiqCanceledOptionalValue.ok THEN Fail ELSE
    Ok([ aiqCanceledOptionalValue |-> aiqCanceledOptionalValue.value ], aiqCanceledOptionalValue.rest)

DecodeAiqCanceledAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeAiqCanceledAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroAiqCanceledAppendage ==
    [ aiqCanceledOptionalValue |-> ZeroAiqCanceledOptionalValue ]

(* Aiq Canceled Appendage at zero, then each field in turn at the values it is checked at *)
CheckedAiqCanceledAppendage ==
    { ZeroAiqCanceledAppendage }
        \cup { [ZeroAiqCanceledAppendage EXCEPT !.aiqCanceledOptionalValue = one] : one \in CheckedAiqCanceledOptionalValue }

(* A run of Aiq Canceled Appendage, written one after another *)
RECURSIVE EncodeAiqCanceledAppendageList(_)
EncodeAiqCanceledAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAiqCanceledAppendage(Head(messages)) \o EncodeAiqCanceledAppendageList(Tail(messages))

(* As many Aiq Canceled Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadAiqCanceledAppendageAll(_)
ReadAiqCanceledAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeAiqCanceledAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAiqCanceledAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Aiq Canceled Appendage of each kind, for the lists that carry them *)
OneAiqCanceledAppendage ==
    { [ZeroAiqCanceledAppendage EXCEPT !.aiqCanceledOptionalValue = [tag |-> UserRefIdxCode4, body |-> ZeroUserRefIdx4]] }

(***************************************************************************)
(* Aiq Canceled Message                                                    *)
(***************************************************************************)

AiqCanceledMessageTail ==
    [ aiqCanceledAppendage : SampleLists(OneAiqCanceledAppendage) ]

EncodeAiqCanceledMessageTail(message) ==
    LET payload == EncodeAiqCanceledAppendageList(message.aiqCanceledAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeAiqCanceledMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        aiqCanceledAppendage == ReadAiqCanceledAppendageAll(framed)
    IN  IF ~aiqCanceledAppendage.ok \/ aiqCanceledAppendage.rest # << >> THEN Fail ELSE
    Ok([ aiqCanceledAppendage |-> aiqCanceledAppendage.value ], beyond)

ZeroAiqCanceledMessageTail ==
    [ aiqCanceledAppendage |-> << >> ]

(* Aiq Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedAiqCanceledMessageTail ==
    { ZeroAiqCanceledMessageTail }
        \cup { [ZeroAiqCanceledMessageTail EXCEPT !.aiqCanceledAppendage = one] : one \in SampleLists(OneAiqCanceledAppendage) }

(* Aiq Canceled Message runs on only when bytes remain, so it is there or it is not *)
WithoutAiqCanceledMessageTail == [there |-> FALSE, value |-> ZeroAiqCanceledMessageTail]

MaybeAiqCanceledMessageTail ==
    { WithoutAiqCanceledMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedAiqCanceledMessageTail }

ReadAiqCanceledMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutAiqCanceledMessageTail, << >>)
    ELSE LET one == DecodeAiqCanceledMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Aiq Canceled Message                                                    *)
(***************************************************************************)

AiqCanceledMessage ==
    [ timestamp                    : Sample(8),
      userRefNum                   : Sample(4),
      decrementShares              : Sample(4),
      orderCancelReason            : Sample(1),
      quantityPreventedFromTrading : Sample(4),
      executionPrice               : Sample(8),
      liquidityFlag                : Sample(1),
      aiqStrategy                  : Sample(1),
      aiqCanceledMessageTail       : MaybeAiqCanceledMessageTail ]

EncodeAiqCanceledMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.decrementShares
        \o message.orderCancelReason
        \o message.quantityPreventedFromTrading
        \o message.executionPrice
        \o message.liquidityFlag
        \o message.aiqStrategy
        \o IF message.aiqCanceledMessageTail.there THEN EncodeAiqCanceledMessageTail(message.aiqCanceledMessageTail.value) ELSE << >>

DecodeAiqCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET decrementShares == ReadBytes(userRefNum.rest, 4) IN IF ~decrementShares.ok THEN Fail ELSE
    LET orderCancelReason == ReadBytes(decrementShares.rest, 1) IN IF ~orderCancelReason.ok THEN Fail ELSE
    LET quantityPreventedFromTrading == ReadBytes(orderCancelReason.rest, 4) IN IF ~quantityPreventedFromTrading.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(quantityPreventedFromTrading.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionPrice.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET aiqStrategy == ReadBytes(liquidityFlag.rest, 1) IN IF ~aiqStrategy.ok THEN Fail ELSE
    LET aiqCanceledMessageTail == ReadAiqCanceledMessageTailMaybe(aiqStrategy.rest) IN IF ~aiqCanceledMessageTail.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         userRefNum                   |-> userRefNum.value,
         decrementShares              |-> decrementShares.value,
         orderCancelReason            |-> orderCancelReason.value,
         quantityPreventedFromTrading |-> quantityPreventedFromTrading.value,
         executionPrice               |-> executionPrice.value,
         liquidityFlag                |-> liquidityFlag.value,
         aiqStrategy                  |-> aiqStrategy.value,
         aiqCanceledMessageTail       |-> aiqCanceledMessageTail.value ], aiqCanceledMessageTail.rest)

ZeroAiqCanceledMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      userRefNum                   |-> [i \in 1 .. 4 |-> 0],
      decrementShares              |-> [i \in 1 .. 4 |-> 0],
      orderCancelReason            |-> [i \in 1 .. 1 |-> 0],
      quantityPreventedFromTrading |-> [i \in 1 .. 4 |-> 0],
      executionPrice               |-> [i \in 1 .. 8 |-> 0],
      liquidityFlag                |-> [i \in 1 .. 1 |-> 0],
      aiqStrategy                  |-> [i \in 1 .. 1 |-> 0],
      aiqCanceledMessageTail       |-> WithoutAiqCanceledMessageTail ]

(* Aiq Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedAiqCanceledMessage ==
    { ZeroAiqCanceledMessage }
        \cup { [ZeroAiqCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAiqCanceledMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroAiqCanceledMessage EXCEPT !.decrementShares = one] : one \in Sample(4) }
        \cup { [ZeroAiqCanceledMessage EXCEPT !.orderCancelReason = one] : one \in Sample(1) }
        \cup { [ZeroAiqCanceledMessage EXCEPT !.quantityPreventedFromTrading = one] : one \in Sample(4) }
        \cup { [ZeroAiqCanceledMessage EXCEPT !.executionPrice = one] : one \in Sample(8) }
        \cup { [ZeroAiqCanceledMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroAiqCanceledMessage EXCEPT !.aiqStrategy = one] : one \in Sample(1) }
        \cup { [ZeroAiqCanceledMessage EXCEPT !.aiqCanceledMessageTail = one] : one \in MaybeAiqCanceledMessageTail }

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
(* Order Executed Optional Value, selected by Order Executed Optional      *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode5 == 28  \* 0x1c

OrderExecutedOptionalValue ==
    [ tag : {UserRefIdxCode5}, body : UserRefIdx5 ]

EncodeOrderExecutedOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode5 -> EncodeUserRefIdx5(message.body)

DecodeOrderExecutedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode5 -> DecodeUserRefIdx5(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderExecutedOptionalValue == [tag |-> UserRefIdxCode5, body |-> ZeroUserRefIdx5]

(* Each Order Executed Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderExecutedOptionalValue ==
    { [tag |-> UserRefIdxCode5, body |-> one] : one \in CheckedUserRefIdx5 }

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
    { [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> UserRefIdxCode5, body |-> ZeroUserRefIdx5]] }

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
      orderExecutedAppendage : SampleLists(OneOrderExecutedAppendage) ]

EncodeOrderExecutedMessage(message) ==
    LET payload == EncodeOrderExecutedAppendageList(message.orderExecutedAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.quantity
            \o message.price
            \o message.liquidityFlag
            \o message.matchNumber
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(userRefNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(price.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(liquidityFlag.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(matchNumber.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
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
         orderExecutedAppendage |-> orderExecutedAppendage.value ], beyond)

ZeroOrderExecutedMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      userRefNum             |-> [i \in 1 .. 4 |-> 0],
      quantity               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      liquidityFlag          |-> [i \in 1 .. 1 |-> 0],
      matchNumber            |-> [i \in 1 .. 8 |-> 0],
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
(* Broken Trade Optional Value, selected by Broken Trade Optional Field    *)
(***************************************************************************)

UserRefIdxCode6 == 28  \* 0x1c

BrokenTradeOptionalValue ==
    [ tag : {UserRefIdxCode6}, body : UserRefIdx6 ]

EncodeBrokenTradeOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode6 -> EncodeUserRefIdx6(message.body)

DecodeBrokenTradeOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode6 -> DecodeUserRefIdx6(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroBrokenTradeOptionalValue == [tag |-> UserRefIdxCode6, body |-> ZeroUserRefIdx6]

(* Each Broken Trade Optional Value in turn, at the values the message it names is checked at *)
CheckedBrokenTradeOptionalValue ==
    { [tag |-> UserRefIdxCode6, body |-> one] : one \in CheckedUserRefIdx6 }

(***************************************************************************)
(* Broken Trade Appendage, framed by Optional Field Length                 *)
(***************************************************************************)

BrokenTradeAppendage ==
    [ brokenTradeOptionalValue : BrokenTradeOptionalValue ]

EncodeBrokenTradeAppendageBody(message) ==
    EncodeUIntBE(message.brokenTradeOptionalValue.tag, 1)
        \o EncodeBrokenTradeOptionalValue(message.brokenTradeOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeBrokenTradeAppendage(message) ==
    LET body == EncodeBrokenTradeAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeBrokenTradeAppendageBody(bytes) ==
    LET brokenTradeOptionalField == ReadUIntBE(bytes, 1) IN IF ~brokenTradeOptionalField.ok THEN Fail ELSE
    LET brokenTradeOptionalValue == DecodeBrokenTradeOptionalValue(brokenTradeOptionalField.value, brokenTradeOptionalField.rest) IN IF ~brokenTradeOptionalValue.ok THEN Fail ELSE
    Ok([ brokenTradeOptionalValue |-> brokenTradeOptionalValue.value ], brokenTradeOptionalValue.rest)

DecodeBrokenTradeAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeBrokenTradeAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroBrokenTradeAppendage ==
    [ brokenTradeOptionalValue |-> ZeroBrokenTradeOptionalValue ]

(* Broken Trade Appendage at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeAppendage ==
    { ZeroBrokenTradeAppendage }
        \cup { [ZeroBrokenTradeAppendage EXCEPT !.brokenTradeOptionalValue = one] : one \in CheckedBrokenTradeOptionalValue }

(* A run of Broken Trade Appendage, written one after another *)
RECURSIVE EncodeBrokenTradeAppendageList(_)
EncodeBrokenTradeAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBrokenTradeAppendage(Head(messages)) \o EncodeBrokenTradeAppendageList(Tail(messages))

(* As many Broken Trade Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadBrokenTradeAppendageAll(_)
ReadBrokenTradeAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeBrokenTradeAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBrokenTradeAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Broken Trade Appendage of each kind, for the lists that carry them *)
OneBrokenTradeAppendage ==
    { [ZeroBrokenTradeAppendage EXCEPT !.brokenTradeOptionalValue = [tag |-> UserRefIdxCode6, body |-> ZeroUserRefIdx6]] }

(***************************************************************************)
(* Broken Trade Message                                                    *)
(***************************************************************************)

BrokenTradeMessageTail ==
    [ brokenTradeAppendage : SampleLists(OneBrokenTradeAppendage) ]

EncodeBrokenTradeMessageTail(message) ==
    LET payload == EncodeBrokenTradeAppendageList(message.brokenTradeAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeBrokenTradeMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        brokenTradeAppendage == ReadBrokenTradeAppendageAll(framed)
    IN  IF ~brokenTradeAppendage.ok \/ brokenTradeAppendage.rest # << >> THEN Fail ELSE
    Ok([ brokenTradeAppendage |-> brokenTradeAppendage.value ], beyond)

ZeroBrokenTradeMessageTail ==
    [ brokenTradeAppendage |-> << >> ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessageTail ==
    { ZeroBrokenTradeMessageTail }
        \cup { [ZeroBrokenTradeMessageTail EXCEPT !.brokenTradeAppendage = one] : one \in SampleLists(OneBrokenTradeAppendage) }

(* Broken Trade Message runs on only when bytes remain, so it is there or it is not *)
WithoutBrokenTradeMessageTail == [there |-> FALSE, value |-> ZeroBrokenTradeMessageTail]

MaybeBrokenTradeMessageTail ==
    { WithoutBrokenTradeMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedBrokenTradeMessageTail }

ReadBrokenTradeMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutBrokenTradeMessageTail, << >>)
    ELSE LET one == DecodeBrokenTradeMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Broken Trade Message                                                    *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timestamp              : Sample(8),
      userRefNum             : Sample(4),
      matchNumber            : Sample(8),
      brokenTradeReason      : Sample(1),
      clordid                : Sample(14),
      brokenTradeMessageTail : MaybeBrokenTradeMessageTail ]

EncodeBrokenTradeMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.matchNumber
        \o message.brokenTradeReason
        \o message.clordid
        \o IF message.brokenTradeMessageTail.there THEN EncodeBrokenTradeMessageTail(message.brokenTradeMessageTail.value) ELSE << >>

DecodeBrokenTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(userRefNum.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET brokenTradeReason == ReadBytes(matchNumber.rest, 1) IN IF ~brokenTradeReason.ok THEN Fail ELSE
    LET clordid == ReadBytes(brokenTradeReason.rest, 14) IN IF ~clordid.ok THEN Fail ELSE
    LET brokenTradeMessageTail == ReadBrokenTradeMessageTailMaybe(clordid.rest) IN IF ~brokenTradeMessageTail.ok THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         userRefNum             |-> userRefNum.value,
         matchNumber            |-> matchNumber.value,
         brokenTradeReason      |-> brokenTradeReason.value,
         clordid                |-> clordid.value,
         brokenTradeMessageTail |-> brokenTradeMessageTail.value ], brokenTradeMessageTail.rest)

ZeroBrokenTradeMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      userRefNum             |-> [i \in 1 .. 4 |-> 0],
      matchNumber            |-> [i \in 1 .. 8 |-> 0],
      brokenTradeReason      |-> [i \in 1 .. 1 |-> 0],
      clordid                |-> [i \in 1 .. 14 |-> 0],
      brokenTradeMessageTail |-> WithoutBrokenTradeMessageTail ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.brokenTradeReason = one] : one \in Sample(1) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.clordid = one] : one \in Sample(14) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.brokenTradeMessageTail = one] : one \in MaybeBrokenTradeMessageTail }

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

UserRefIdxCode7 == 28  \* 0x1c

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

RejectedOrderMessageTail ==
    [ rejectedOrderAppendage : SampleLists(OneRejectedOrderAppendage) ]

EncodeRejectedOrderMessageTail(message) ==
    LET payload == EncodeRejectedOrderAppendageList(message.rejectedOrderAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeRejectedOrderMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        rejectedOrderAppendage == ReadRejectedOrderAppendageAll(framed)
    IN  IF ~rejectedOrderAppendage.ok \/ rejectedOrderAppendage.rest # << >> THEN Fail ELSE
    Ok([ rejectedOrderAppendage |-> rejectedOrderAppendage.value ], beyond)

ZeroRejectedOrderMessageTail ==
    [ rejectedOrderAppendage |-> << >> ]

(* Rejected Order Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectedOrderMessageTail ==
    { ZeroRejectedOrderMessageTail }
        \cup { [ZeroRejectedOrderMessageTail EXCEPT !.rejectedOrderAppendage = one] : one \in SampleLists(OneRejectedOrderAppendage) }

(* Rejected Order Message runs on only when bytes remain, so it is there or it is not *)
WithoutRejectedOrderMessageTail == [there |-> FALSE, value |-> ZeroRejectedOrderMessageTail]

MaybeRejectedOrderMessageTail ==
    { WithoutRejectedOrderMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedRejectedOrderMessageTail }

ReadRejectedOrderMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutRejectedOrderMessageTail, << >>)
    ELSE LET one == DecodeRejectedOrderMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Rejected Order Message                                                  *)
(***************************************************************************)

RejectedOrderMessage ==
    [ timestamp                : Sample(8),
      userRefNum               : Sample(4),
      rejectedOrderReason      : Sample(2),
      clordid                  : Sample(14),
      rejectedOrderMessageTail : MaybeRejectedOrderMessageTail ]

EncodeRejectedOrderMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.rejectedOrderReason
        \o message.clordid
        \o IF message.rejectedOrderMessageTail.there THEN EncodeRejectedOrderMessageTail(message.rejectedOrderMessageTail.value) ELSE << >>

DecodeRejectedOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET rejectedOrderReason == ReadBytes(userRefNum.rest, 2) IN IF ~rejectedOrderReason.ok THEN Fail ELSE
    LET clordid == ReadBytes(rejectedOrderReason.rest, 14) IN IF ~clordid.ok THEN Fail ELSE
    LET rejectedOrderMessageTail == ReadRejectedOrderMessageTailMaybe(clordid.rest) IN IF ~rejectedOrderMessageTail.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         userRefNum               |-> userRefNum.value,
         rejectedOrderReason      |-> rejectedOrderReason.value,
         clordid                  |-> clordid.value,
         rejectedOrderMessageTail |-> rejectedOrderMessageTail.value ], rejectedOrderMessageTail.rest)

ZeroRejectedOrderMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      userRefNum               |-> [i \in 1 .. 4 |-> 0],
      rejectedOrderReason      |-> [i \in 1 .. 2 |-> 0],
      clordid                  |-> [i \in 1 .. 14 |-> 0],
      rejectedOrderMessageTail |-> WithoutRejectedOrderMessageTail ]

(* Rejected Order Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectedOrderMessage ==
    { ZeroRejectedOrderMessage }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.rejectedOrderReason = one] : one \in Sample(2) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.clordid = one] : one \in Sample(14) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.rejectedOrderMessageTail = one] : one \in MaybeRejectedOrderMessageTail }

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
(* Cancel Pending Optional Value, selected by Cancel Pending Optional      *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode8 == 28  \* 0x1c

CancelPendingOptionalValue ==
    [ tag : {UserRefIdxCode8}, body : UserRefIdx8 ]

EncodeCancelPendingOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode8 -> EncodeUserRefIdx8(message.body)

DecodeCancelPendingOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode8 -> DecodeUserRefIdx8(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCancelPendingOptionalValue == [tag |-> UserRefIdxCode8, body |-> ZeroUserRefIdx8]

(* Each Cancel Pending Optional Value in turn, at the values the message it names is checked at *)
CheckedCancelPendingOptionalValue ==
    { [tag |-> UserRefIdxCode8, body |-> one] : one \in CheckedUserRefIdx8 }

(***************************************************************************)
(* Cancel Pending Appendage, framed by Optional Field Length               *)
(***************************************************************************)

CancelPendingAppendage ==
    [ cancelPendingOptionalValue : CancelPendingOptionalValue ]

EncodeCancelPendingAppendageBody(message) ==
    EncodeUIntBE(message.cancelPendingOptionalValue.tag, 1)
        \o EncodeCancelPendingOptionalValue(message.cancelPendingOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeCancelPendingAppendage(message) ==
    LET body == EncodeCancelPendingAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeCancelPendingAppendageBody(bytes) ==
    LET cancelPendingOptionalField == ReadUIntBE(bytes, 1) IN IF ~cancelPendingOptionalField.ok THEN Fail ELSE
    LET cancelPendingOptionalValue == DecodeCancelPendingOptionalValue(cancelPendingOptionalField.value, cancelPendingOptionalField.rest) IN IF ~cancelPendingOptionalValue.ok THEN Fail ELSE
    Ok([ cancelPendingOptionalValue |-> cancelPendingOptionalValue.value ], cancelPendingOptionalValue.rest)

DecodeCancelPendingAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeCancelPendingAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroCancelPendingAppendage ==
    [ cancelPendingOptionalValue |-> ZeroCancelPendingOptionalValue ]

(* Cancel Pending Appendage at zero, then each field in turn at the values it is checked at *)
CheckedCancelPendingAppendage ==
    { ZeroCancelPendingAppendage }
        \cup { [ZeroCancelPendingAppendage EXCEPT !.cancelPendingOptionalValue = one] : one \in CheckedCancelPendingOptionalValue }

(* A run of Cancel Pending Appendage, written one after another *)
RECURSIVE EncodeCancelPendingAppendageList(_)
EncodeCancelPendingAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCancelPendingAppendage(Head(messages)) \o EncodeCancelPendingAppendageList(Tail(messages))

(* As many Cancel Pending Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadCancelPendingAppendageAll(_)
ReadCancelPendingAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeCancelPendingAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCancelPendingAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cancel Pending Appendage of each kind, for the lists that carry them *)
OneCancelPendingAppendage ==
    { [ZeroCancelPendingAppendage EXCEPT !.cancelPendingOptionalValue = [tag |-> UserRefIdxCode8, body |-> ZeroUserRefIdx8]] }

(***************************************************************************)
(* Cancel Pending Message                                                  *)
(***************************************************************************)

CancelPendingMessageTail ==
    [ cancelPendingAppendage : SampleLists(OneCancelPendingAppendage) ]

EncodeCancelPendingMessageTail(message) ==
    LET payload == EncodeCancelPendingAppendageList(message.cancelPendingAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeCancelPendingMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        cancelPendingAppendage == ReadCancelPendingAppendageAll(framed)
    IN  IF ~cancelPendingAppendage.ok \/ cancelPendingAppendage.rest # << >> THEN Fail ELSE
    Ok([ cancelPendingAppendage |-> cancelPendingAppendage.value ], beyond)

ZeroCancelPendingMessageTail ==
    [ cancelPendingAppendage |-> << >> ]

(* Cancel Pending Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelPendingMessageTail ==
    { ZeroCancelPendingMessageTail }
        \cup { [ZeroCancelPendingMessageTail EXCEPT !.cancelPendingAppendage = one] : one \in SampleLists(OneCancelPendingAppendage) }

(* Cancel Pending Message runs on only when bytes remain, so it is there or it is not *)
WithoutCancelPendingMessageTail == [there |-> FALSE, value |-> ZeroCancelPendingMessageTail]

MaybeCancelPendingMessageTail ==
    { WithoutCancelPendingMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedCancelPendingMessageTail }

ReadCancelPendingMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutCancelPendingMessageTail, << >>)
    ELSE LET one == DecodeCancelPendingMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Cancel Pending Message                                                  *)
(***************************************************************************)

CancelPendingMessage ==
    [ timestamp                : Sample(8),
      userRefNum               : Sample(4),
      cancelPendingMessageTail : MaybeCancelPendingMessageTail ]

EncodeCancelPendingMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o IF message.cancelPendingMessageTail.there THEN EncodeCancelPendingMessageTail(message.cancelPendingMessageTail.value) ELSE << >>

DecodeCancelPendingMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET cancelPendingMessageTail == ReadCancelPendingMessageTailMaybe(userRefNum.rest) IN IF ~cancelPendingMessageTail.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         userRefNum               |-> userRefNum.value,
         cancelPendingMessageTail |-> cancelPendingMessageTail.value ], cancelPendingMessageTail.rest)

ZeroCancelPendingMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      userRefNum               |-> [i \in 1 .. 4 |-> 0],
      cancelPendingMessageTail |-> WithoutCancelPendingMessageTail ]

(* Cancel Pending Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelPendingMessage ==
    { ZeroCancelPendingMessage }
        \cup { [ZeroCancelPendingMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelPendingMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelPendingMessage EXCEPT !.cancelPendingMessageTail = one] : one \in MaybeCancelPendingMessageTail }

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
(* Cancel Reject Optional Value, selected by Cancel Reject Optional Field  *)
(***************************************************************************)

UserRefIdxCode9 == 28  \* 0x1c

CancelRejectOptionalValue ==
    [ tag : {UserRefIdxCode9}, body : UserRefIdx9 ]

EncodeCancelRejectOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode9 -> EncodeUserRefIdx9(message.body)

DecodeCancelRejectOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode9 -> DecodeUserRefIdx9(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCancelRejectOptionalValue == [tag |-> UserRefIdxCode9, body |-> ZeroUserRefIdx9]

(* Each Cancel Reject Optional Value in turn, at the values the message it names is checked at *)
CheckedCancelRejectOptionalValue ==
    { [tag |-> UserRefIdxCode9, body |-> one] : one \in CheckedUserRefIdx9 }

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
    { [ZeroCancelRejectAppendage EXCEPT !.cancelRejectOptionalValue = [tag |-> UserRefIdxCode9, body |-> ZeroUserRefIdx9]] }

(***************************************************************************)
(* Cancel Reject Message                                                   *)
(***************************************************************************)

CancelRejectMessageTail ==
    [ cancelRejectAppendage : SampleLists(OneCancelRejectAppendage) ]

EncodeCancelRejectMessageTail(message) ==
    LET payload == EncodeCancelRejectAppendageList(message.cancelRejectAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeCancelRejectMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        cancelRejectAppendage == ReadCancelRejectAppendageAll(framed)
    IN  IF ~cancelRejectAppendage.ok \/ cancelRejectAppendage.rest # << >> THEN Fail ELSE
    Ok([ cancelRejectAppendage |-> cancelRejectAppendage.value ], beyond)

ZeroCancelRejectMessageTail ==
    [ cancelRejectAppendage |-> << >> ]

(* Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectMessageTail ==
    { ZeroCancelRejectMessageTail }
        \cup { [ZeroCancelRejectMessageTail EXCEPT !.cancelRejectAppendage = one] : one \in SampleLists(OneCancelRejectAppendage) }

(* Cancel Reject Message runs on only when bytes remain, so it is there or it is not *)
WithoutCancelRejectMessageTail == [there |-> FALSE, value |-> ZeroCancelRejectMessageTail]

MaybeCancelRejectMessageTail ==
    { WithoutCancelRejectMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedCancelRejectMessageTail }

ReadCancelRejectMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutCancelRejectMessageTail, << >>)
    ELSE LET one == DecodeCancelRejectMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Cancel Reject Message                                                   *)
(***************************************************************************)

CancelRejectMessage ==
    [ timestamp               : Sample(8),
      userRefNum              : Sample(4),
      cancelRejectMessageTail : MaybeCancelRejectMessageTail ]

EncodeCancelRejectMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o IF message.cancelRejectMessageTail.there THEN EncodeCancelRejectMessageTail(message.cancelRejectMessageTail.value) ELSE << >>

DecodeCancelRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET cancelRejectMessageTail == ReadCancelRejectMessageTailMaybe(userRefNum.rest) IN IF ~cancelRejectMessageTail.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         userRefNum              |-> userRefNum.value,
         cancelRejectMessageTail |-> cancelRejectMessageTail.value ], cancelRejectMessageTail.rest)

ZeroCancelRejectMessage ==
    [ timestamp               |-> [i \in 1 .. 8 |-> 0],
      userRefNum              |-> [i \in 1 .. 4 |-> 0],
      cancelRejectMessageTail |-> WithoutCancelRejectMessageTail ]

(* Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectMessage ==
    { ZeroCancelRejectMessage }
        \cup { [ZeroCancelRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.cancelRejectMessageTail = one] : one \in MaybeCancelRejectMessageTail }

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
(* Order Priority Update Optional Value, selected by Order Priority Update *)
(* Optional Field                                                          *)
(***************************************************************************)

UserRefIdxCode10 == 28  \* 0x1c

OrderPriorityUpdateOptionalValue ==
    [ tag : {UserRefIdxCode10}, body : UserRefIdx10 ]

EncodeOrderPriorityUpdateOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode10 -> EncodeUserRefIdx10(message.body)

DecodeOrderPriorityUpdateOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode10 -> DecodeUserRefIdx10(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderPriorityUpdateOptionalValue == [tag |-> UserRefIdxCode10, body |-> ZeroUserRefIdx10]

(* Each Order Priority Update Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderPriorityUpdateOptionalValue ==
    { [tag |-> UserRefIdxCode10, body |-> one] : one \in CheckedUserRefIdx10 }

(***************************************************************************)
(* Order Priority Update Appendage, framed by Optional Field Length        *)
(***************************************************************************)

OrderPriorityUpdateAppendage ==
    [ orderPriorityUpdateOptionalValue : OrderPriorityUpdateOptionalValue ]

EncodeOrderPriorityUpdateAppendageBody(message) ==
    EncodeUIntBE(message.orderPriorityUpdateOptionalValue.tag, 1)
        \o EncodeOrderPriorityUpdateOptionalValue(message.orderPriorityUpdateOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeOrderPriorityUpdateAppendage(message) ==
    LET body == EncodeOrderPriorityUpdateAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeOrderPriorityUpdateAppendageBody(bytes) ==
    LET orderPriorityUpdateOptionalField == ReadUIntBE(bytes, 1) IN IF ~orderPriorityUpdateOptionalField.ok THEN Fail ELSE
    LET orderPriorityUpdateOptionalValue == DecodeOrderPriorityUpdateOptionalValue(orderPriorityUpdateOptionalField.value, orderPriorityUpdateOptionalField.rest) IN IF ~orderPriorityUpdateOptionalValue.ok THEN Fail ELSE
    Ok([ orderPriorityUpdateOptionalValue |-> orderPriorityUpdateOptionalValue.value ], orderPriorityUpdateOptionalValue.rest)

DecodeOrderPriorityUpdateAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeOrderPriorityUpdateAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroOrderPriorityUpdateAppendage ==
    [ orderPriorityUpdateOptionalValue |-> ZeroOrderPriorityUpdateOptionalValue ]

(* Order Priority Update Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOrderPriorityUpdateAppendage ==
    { ZeroOrderPriorityUpdateAppendage }
        \cup { [ZeroOrderPriorityUpdateAppendage EXCEPT !.orderPriorityUpdateOptionalValue = one] : one \in CheckedOrderPriorityUpdateOptionalValue }

(* A run of Order Priority Update Appendage, written one after another *)
RECURSIVE EncodeOrderPriorityUpdateAppendageList(_)
EncodeOrderPriorityUpdateAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderPriorityUpdateAppendage(Head(messages)) \o EncodeOrderPriorityUpdateAppendageList(Tail(messages))

(* As many Order Priority Update Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadOrderPriorityUpdateAppendageAll(_)
ReadOrderPriorityUpdateAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeOrderPriorityUpdateAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderPriorityUpdateAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Priority Update Appendage of each kind, for the lists that carry them *)
OneOrderPriorityUpdateAppendage ==
    { [ZeroOrderPriorityUpdateAppendage EXCEPT !.orderPriorityUpdateOptionalValue = [tag |-> UserRefIdxCode10, body |-> ZeroUserRefIdx10]] }

(***************************************************************************)
(* Order Priority Update Message                                           *)
(***************************************************************************)

OrderPriorityUpdateMessageTail ==
    [ orderPriorityUpdateAppendage : SampleLists(OneOrderPriorityUpdateAppendage) ]

EncodeOrderPriorityUpdateMessageTail(message) ==
    LET payload == EncodeOrderPriorityUpdateAppendageList(message.orderPriorityUpdateAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderPriorityUpdateMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        orderPriorityUpdateAppendage == ReadOrderPriorityUpdateAppendageAll(framed)
    IN  IF ~orderPriorityUpdateAppendage.ok \/ orderPriorityUpdateAppendage.rest # << >> THEN Fail ELSE
    Ok([ orderPriorityUpdateAppendage |-> orderPriorityUpdateAppendage.value ], beyond)

ZeroOrderPriorityUpdateMessageTail ==
    [ orderPriorityUpdateAppendage |-> << >> ]

(* Order Priority Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderPriorityUpdateMessageTail ==
    { ZeroOrderPriorityUpdateMessageTail }
        \cup { [ZeroOrderPriorityUpdateMessageTail EXCEPT !.orderPriorityUpdateAppendage = one] : one \in SampleLists(OneOrderPriorityUpdateAppendage) }

(* Order Priority Update Message runs on only when bytes remain, so it is there or it is not *)
WithoutOrderPriorityUpdateMessageTail == [there |-> FALSE, value |-> ZeroOrderPriorityUpdateMessageTail]

MaybeOrderPriorityUpdateMessageTail ==
    { WithoutOrderPriorityUpdateMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedOrderPriorityUpdateMessageTail }

ReadOrderPriorityUpdateMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutOrderPriorityUpdateMessageTail, << >>)
    ELSE LET one == DecodeOrderPriorityUpdateMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Order Priority Update Message                                           *)
(***************************************************************************)

OrderPriorityUpdateMessage ==
    [ timestamp                      : Sample(8),
      userRefNum                     : Sample(4),
      price                          : Sample(8),
      display                        : Sample(1),
      orderReferenceNumber           : Sample(8),
      orderPriorityUpdateMessageTail : MaybeOrderPriorityUpdateMessageTail ]

EncodeOrderPriorityUpdateMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.price
        \o message.display
        \o message.orderReferenceNumber
        \o IF message.orderPriorityUpdateMessageTail.there THEN EncodeOrderPriorityUpdateMessageTail(message.orderPriorityUpdateMessageTail.value) ELSE << >>

DecodeOrderPriorityUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET price == ReadBytes(userRefNum.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET display == ReadBytes(price.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(display.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET orderPriorityUpdateMessageTail == ReadOrderPriorityUpdateMessageTailMaybe(orderReferenceNumber.rest) IN IF ~orderPriorityUpdateMessageTail.ok THEN Fail ELSE
    Ok([ timestamp                      |-> timestamp.value,
         userRefNum                     |-> userRefNum.value,
         price                          |-> price.value,
         display                        |-> display.value,
         orderReferenceNumber           |-> orderReferenceNumber.value,
         orderPriorityUpdateMessageTail |-> orderPriorityUpdateMessageTail.value ], orderPriorityUpdateMessageTail.rest)

ZeroOrderPriorityUpdateMessage ==
    [ timestamp                      |-> [i \in 1 .. 8 |-> 0],
      userRefNum                     |-> [i \in 1 .. 4 |-> 0],
      price                          |-> [i \in 1 .. 8 |-> 0],
      display                        |-> [i \in 1 .. 1 |-> 0],
      orderReferenceNumber           |-> [i \in 1 .. 8 |-> 0],
      orderPriorityUpdateMessageTail |-> WithoutOrderPriorityUpdateMessageTail ]

(* Order Priority Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderPriorityUpdateMessage ==
    { ZeroOrderPriorityUpdateMessage }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.orderPriorityUpdateMessageTail = one] : one \in MaybeOrderPriorityUpdateMessageTail }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx11 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx11(message) ==
    message.userRefIdx

DecodeUserRefIdx11(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx11 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx11 ==
    { ZeroUserRefIdx11 }
        \cup { [ZeroUserRefIdx11 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Shares Located: 1 bytes                                                 *)
(***************************************************************************)

SharesLocated2 ==
    [ sharesLocated : Sample(1) ]

EncodeSharesLocated2(message) ==
    message.sharesLocated

DecodeSharesLocated2(bytes) ==
    LET sharesLocated == ReadBytes(bytes, 1) IN IF ~sharesLocated.ok THEN Fail ELSE
    Ok([ sharesLocated |-> sharesLocated.value ], sharesLocated.rest)

ZeroSharesLocated2 ==
    [ sharesLocated |-> [i \in 1 .. 1 |-> 0] ]

(* Shares Located at zero, then each field in turn at the values it is checked at *)
CheckedSharesLocated2 ==
    { ZeroSharesLocated2 }
        \cup { [ZeroSharesLocated2 EXCEPT !.sharesLocated = one] : one \in Sample(1) }

(***************************************************************************)
(* Locate Broker: 4 bytes                                                  *)
(***************************************************************************)

LocateBroker ==
    [ locateBroker : Sample(4) ]

EncodeLocateBroker(message) ==
    message.locateBroker

DecodeLocateBroker(bytes) ==
    LET locateBroker == ReadBytes(bytes, 4) IN IF ~locateBroker.ok THEN Fail ELSE
    Ok([ locateBroker |-> locateBroker.value ], locateBroker.rest)

ZeroLocateBroker ==
    [ locateBroker |-> [i \in 1 .. 4 |-> 0] ]

(* Locate Broker at zero, then each field in turn at the values it is checked at *)
CheckedLocateBroker ==
    { ZeroLocateBroker }
        \cup { [ZeroLocateBroker EXCEPT !.locateBroker = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Modified Optional Value, selected by Order Modified Optional      *)
(* Field                                                                   *)
(***************************************************************************)

UserRefIdxCode11 == 28  \* 0x1c
SharesLocatedCode2 == 25  \* 0x19
LocateBrokerCode == 26  \* 0x1a

OrderModifiedOptionalValue ==
    [ tag : {UserRefIdxCode11}, body : UserRefIdx11 ]
        \cup [ tag : {SharesLocatedCode2}, body : SharesLocated2 ]
        \cup [ tag : {LocateBrokerCode}, body : LocateBroker ]

EncodeOrderModifiedOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode11 -> EncodeUserRefIdx11(message.body)
      [] message.tag = SharesLocatedCode2 -> EncodeSharesLocated2(message.body)
      [] message.tag = LocateBrokerCode -> EncodeLocateBroker(message.body)

DecodeOrderModifiedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode11 -> DecodeUserRefIdx11(bytes)
              [] tag = SharesLocatedCode2 -> DecodeSharesLocated2(bytes)
              [] tag = LocateBrokerCode -> DecodeLocateBroker(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderModifiedOptionalValue == [tag |-> UserRefIdxCode11, body |-> ZeroUserRefIdx11]

(* Each Order Modified Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderModifiedOptionalValue ==
    { [tag |-> UserRefIdxCode11, body |-> one] : one \in CheckedUserRefIdx11 }
        \cup { [tag |-> SharesLocatedCode2, body |-> one] : one \in CheckedSharesLocated2 }
        \cup { [tag |-> LocateBrokerCode, body |-> one] : one \in CheckedLocateBroker }

(***************************************************************************)
(* Order Modified Appendage, framed by Optional Field Length               *)
(***************************************************************************)

OrderModifiedAppendage ==
    [ orderModifiedOptionalValue : OrderModifiedOptionalValue ]

EncodeOrderModifiedAppendageBody(message) ==
    EncodeUIntBE(message.orderModifiedOptionalValue.tag, 1)
        \o EncodeOrderModifiedOptionalValue(message.orderModifiedOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeOrderModifiedAppendage(message) ==
    LET body == EncodeOrderModifiedAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeOrderModifiedAppendageBody(bytes) ==
    LET orderModifiedOptionalField == ReadUIntBE(bytes, 1) IN IF ~orderModifiedOptionalField.ok THEN Fail ELSE
    LET orderModifiedOptionalValue == DecodeOrderModifiedOptionalValue(orderModifiedOptionalField.value, orderModifiedOptionalField.rest) IN IF ~orderModifiedOptionalValue.ok THEN Fail ELSE
    Ok([ orderModifiedOptionalValue |-> orderModifiedOptionalValue.value ], orderModifiedOptionalValue.rest)

DecodeOrderModifiedAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeOrderModifiedAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroOrderModifiedAppendage ==
    [ orderModifiedOptionalValue |-> ZeroOrderModifiedOptionalValue ]

(* Order Modified Appendage at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedAppendage ==
    { ZeroOrderModifiedAppendage }
        \cup { [ZeroOrderModifiedAppendage EXCEPT !.orderModifiedOptionalValue = one] : one \in CheckedOrderModifiedOptionalValue }

(* A run of Order Modified Appendage, written one after another *)
RECURSIVE EncodeOrderModifiedAppendageList(_)
EncodeOrderModifiedAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderModifiedAppendage(Head(messages)) \o EncodeOrderModifiedAppendageList(Tail(messages))

(* As many Order Modified Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadOrderModifiedAppendageAll(_)
ReadOrderModifiedAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeOrderModifiedAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderModifiedAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Modified Appendage of each kind, for the lists that carry them *)
OneOrderModifiedAppendage ==
    { [ZeroOrderModifiedAppendage EXCEPT !.orderModifiedOptionalValue = [tag |-> UserRefIdxCode11, body |-> ZeroUserRefIdx11]],
      [ZeroOrderModifiedAppendage EXCEPT !.orderModifiedOptionalValue = [tag |-> SharesLocatedCode2, body |-> ZeroSharesLocated2]],
      [ZeroOrderModifiedAppendage EXCEPT !.orderModifiedOptionalValue = [tag |-> LocateBrokerCode, body |-> ZeroLocateBroker]] }

(***************************************************************************)
(* Order Modified Message                                                  *)
(***************************************************************************)

OrderModifiedMessageTail ==
    [ orderModifiedAppendage : SampleLists(OneOrderModifiedAppendage) ]

EncodeOrderModifiedMessageTail(message) ==
    LET payload == EncodeOrderModifiedAppendageList(message.orderModifiedAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderModifiedMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        orderModifiedAppendage == ReadOrderModifiedAppendageAll(framed)
    IN  IF ~orderModifiedAppendage.ok \/ orderModifiedAppendage.rest # << >> THEN Fail ELSE
    Ok([ orderModifiedAppendage |-> orderModifiedAppendage.value ], beyond)

ZeroOrderModifiedMessageTail ==
    [ orderModifiedAppendage |-> << >> ]

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessageTail ==
    { ZeroOrderModifiedMessageTail }
        \cup { [ZeroOrderModifiedMessageTail EXCEPT !.orderModifiedAppendage = one] : one \in SampleLists(OneOrderModifiedAppendage) }

(* Order Modified Message runs on only when bytes remain, so it is there or it is not *)
WithoutOrderModifiedMessageTail == [there |-> FALSE, value |-> ZeroOrderModifiedMessageTail]

MaybeOrderModifiedMessageTail ==
    { WithoutOrderModifiedMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedOrderModifiedMessageTail }

ReadOrderModifiedMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutOrderModifiedMessageTail, << >>)
    ELSE LET one == DecodeOrderModifiedMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Order Modified Message                                                  *)
(***************************************************************************)

OrderModifiedMessage ==
    [ timestamp                : Sample(8),
      userRefNum               : Sample(4),
      side                     : Sample(1),
      quantity                 : Sample(4),
      orderModifiedMessageTail : MaybeOrderModifiedMessageTail ]

EncodeOrderModifiedMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.side
        \o message.quantity
        \o IF message.orderModifiedMessageTail.there THEN EncodeOrderModifiedMessageTail(message.orderModifiedMessageTail.value) ELSE << >>

DecodeOrderModifiedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET side == ReadBytes(userRefNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderModifiedMessageTail == ReadOrderModifiedMessageTailMaybe(quantity.rest) IN IF ~orderModifiedMessageTail.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         userRefNum               |-> userRefNum.value,
         side                     |-> side.value,
         quantity                 |-> quantity.value,
         orderModifiedMessageTail |-> orderModifiedMessageTail.value ], orderModifiedMessageTail.rest)

ZeroOrderModifiedMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      userRefNum               |-> [i \in 1 .. 4 |-> 0],
      side                     |-> [i \in 1 .. 1 |-> 0],
      quantity                 |-> [i \in 1 .. 4 |-> 0],
      orderModifiedMessageTail |-> WithoutOrderModifiedMessageTail ]

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.orderModifiedMessageTail = one] : one \in MaybeOrderModifiedMessageTail }

(***************************************************************************)
(* Display Quantity: 4 bytes                                               *)
(***************************************************************************)

DisplayQuantity ==
    [ displayQuantity : Sample(4) ]

EncodeDisplayQuantity(message) ==
    message.displayQuantity

DecodeDisplayQuantity(bytes) ==
    LET displayQuantity == ReadBytes(bytes, 4) IN IF ~displayQuantity.ok THEN Fail ELSE
    Ok([ displayQuantity |-> displayQuantity.value ], displayQuantity.rest)

ZeroDisplayQuantity ==
    [ displayQuantity |-> [i \in 1 .. 4 |-> 0] ]

(* Display Quantity at zero, then each field in turn at the values it is checked at *)
CheckedDisplayQuantity ==
    { ZeroDisplayQuantity }
        \cup { [ZeroDisplayQuantity EXCEPT !.displayQuantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Display Price: 8 bytes                                                  *)
(***************************************************************************)

DisplayPrice ==
    [ displayPrice : Sample(8) ]

EncodeDisplayPrice(message) ==
    message.displayPrice

DecodeDisplayPrice(bytes) ==
    LET displayPrice == ReadBytes(bytes, 8) IN IF ~displayPrice.ok THEN Fail ELSE
    Ok([ displayPrice |-> displayPrice.value ], displayPrice.rest)

ZeroDisplayPrice ==
    [ displayPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Display Price at zero, then each field in turn at the values it is checked at *)
CheckedDisplayPrice ==
    { ZeroDisplayPrice }
        \cup { [ZeroDisplayPrice EXCEPT !.displayPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Secondary Ord Ref Num: 8 bytes                                          *)
(***************************************************************************)

SecondaryOrdRefNum ==
    [ secondaryOrdRefNum : Sample(8) ]

EncodeSecondaryOrdRefNum(message) ==
    message.secondaryOrdRefNum

DecodeSecondaryOrdRefNum(bytes) ==
    LET secondaryOrdRefNum == ReadBytes(bytes, 8) IN IF ~secondaryOrdRefNum.ok THEN Fail ELSE
    Ok([ secondaryOrdRefNum |-> secondaryOrdRefNum.value ], secondaryOrdRefNum.rest)

ZeroSecondaryOrdRefNum ==
    [ secondaryOrdRefNum |-> [i \in 1 .. 8 |-> 0] ]

(* Secondary Ord Ref Num at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryOrdRefNum ==
    { ZeroSecondaryOrdRefNum }
        \cup { [ZeroSecondaryOrdRefNum EXCEPT !.secondaryOrdRefNum = one] : one \in Sample(8) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx12 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx12(message) ==
    message.userRefIdx

DecodeUserRefIdx12(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx12 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx12 ==
    { ZeroUserRefIdx12 }
        \cup { [ZeroUserRefIdx12 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Restated Optional Value, selected by Order Restated Optional      *)
(* Field                                                                   *)
(***************************************************************************)

DisplayQuantityCode == 22  \* 0x16
DisplayPriceCode == 23  \* 0x17
SecondaryOrdRefNumCode == 1  \* 0x01
UserRefIdxCode12 == 28  \* 0x1c

OrderRestatedOptionalValue ==
    [ tag : {DisplayQuantityCode}, body : DisplayQuantity ]
        \cup [ tag : {DisplayPriceCode}, body : DisplayPrice ]
        \cup [ tag : {SecondaryOrdRefNumCode}, body : SecondaryOrdRefNum ]
        \cup [ tag : {UserRefIdxCode12}, body : UserRefIdx12 ]

EncodeOrderRestatedOptionalValue(message) ==
    CASE message.tag = DisplayQuantityCode -> EncodeDisplayQuantity(message.body)
      [] message.tag = DisplayPriceCode -> EncodeDisplayPrice(message.body)
      [] message.tag = SecondaryOrdRefNumCode -> EncodeSecondaryOrdRefNum(message.body)
      [] message.tag = UserRefIdxCode12 -> EncodeUserRefIdx12(message.body)

DecodeOrderRestatedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = DisplayQuantityCode -> DecodeDisplayQuantity(bytes)
              [] tag = DisplayPriceCode -> DecodeDisplayPrice(bytes)
              [] tag = SecondaryOrdRefNumCode -> DecodeSecondaryOrdRefNum(bytes)
              [] tag = UserRefIdxCode12 -> DecodeUserRefIdx12(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderRestatedOptionalValue == [tag |-> DisplayQuantityCode, body |-> ZeroDisplayQuantity]

(* Each Order Restated Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderRestatedOptionalValue ==
    { [tag |-> DisplayQuantityCode, body |-> one] : one \in CheckedDisplayQuantity }
        \cup { [tag |-> DisplayPriceCode, body |-> one] : one \in CheckedDisplayPrice }
        \cup { [tag |-> SecondaryOrdRefNumCode, body |-> one] : one \in CheckedSecondaryOrdRefNum }
        \cup { [tag |-> UserRefIdxCode12, body |-> one] : one \in CheckedUserRefIdx12 }

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
    { [ZeroOrderRestatedAppendage EXCEPT !.orderRestatedOptionalValue = [tag |-> DisplayQuantityCode, body |-> ZeroDisplayQuantity]],
      [ZeroOrderRestatedAppendage EXCEPT !.orderRestatedOptionalValue = [tag |-> DisplayPriceCode, body |-> ZeroDisplayPrice]],
      [ZeroOrderRestatedAppendage EXCEPT !.orderRestatedOptionalValue = [tag |-> SecondaryOrdRefNumCode, body |-> ZeroSecondaryOrdRefNum]],
      [ZeroOrderRestatedAppendage EXCEPT !.orderRestatedOptionalValue = [tag |-> UserRefIdxCode12, body |-> ZeroUserRefIdx12]] }

(***************************************************************************)
(* Order Restated Message                                                  *)
(***************************************************************************)

OrderRestatedMessage ==
    [ timestamp              : Sample(8),
      userRefNum             : Sample(4),
      orderRestatedReason    : Sample(1),
      orderRestatedAppendage : SampleLists(OneOrderRestatedAppendage) ]

EncodeOrderRestatedMessage(message) ==
    LET payload == EncodeOrderRestatedAppendageList(message.orderRestatedAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.orderRestatedReason
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderRestatedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET orderRestatedReason == ReadBytes(userRefNum.rest, 1) IN IF ~orderRestatedReason.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(orderRestatedReason.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        orderRestatedAppendage == ReadOrderRestatedAppendageAll(framed)
    IN  IF ~orderRestatedAppendage.ok \/ orderRestatedAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp              |-> timestamp.value,
         userRefNum             |-> userRefNum.value,
         orderRestatedReason    |-> orderRestatedReason.value,
         orderRestatedAppendage |-> orderRestatedAppendage.value ], beyond)

ZeroOrderRestatedMessage ==
    [ timestamp              |-> [i \in 1 .. 8 |-> 0],
      userRefNum             |-> [i \in 1 .. 4 |-> 0],
      orderRestatedReason    |-> [i \in 1 .. 1 |-> 0],
      orderRestatedAppendage |-> << >> ]

(* Order Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedMessage ==
    { ZeroOrderRestatedMessage }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.orderRestatedReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.orderRestatedAppendage = one] : one \in SampleLists(OneOrderRestatedAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx13 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx13(message) ==
    message.userRefIdx

DecodeUserRefIdx13(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx13 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx13 ==
    { ZeroUserRefIdx13 }
        \cup { [ZeroUserRefIdx13 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Account Query Response Optional Value, selected by Account Query        *)
(* Response Optional Field                                                 *)
(***************************************************************************)

UserRefIdxCode13 == 28  \* 0x1c

AccountQueryResponseOptionalValue ==
    [ tag : {UserRefIdxCode13}, body : UserRefIdx13 ]

EncodeAccountQueryResponseOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode13 -> EncodeUserRefIdx13(message.body)

DecodeAccountQueryResponseOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode13 -> DecodeUserRefIdx13(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAccountQueryResponseOptionalValue == [tag |-> UserRefIdxCode13, body |-> ZeroUserRefIdx13]

(* Each Account Query Response Optional Value in turn, at the values the message it names is checked at *)
CheckedAccountQueryResponseOptionalValue ==
    { [tag |-> UserRefIdxCode13, body |-> one] : one \in CheckedUserRefIdx13 }

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
    { [ZeroAccountQueryResponseAppendage EXCEPT !.accountQueryResponseOptionalValue = [tag |-> UserRefIdxCode13, body |-> ZeroUserRefIdx13]] }

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
(* Side: 1 bytes                                                           *)
(***************************************************************************)

Side ==
    [ side : Sample(1) ]

EncodeSide(message) ==
    message.side

DecodeSide(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ side |-> side.value ], side.rest)

ZeroSide ==
    [ side |-> [i \in 1 .. 1 |-> 0] ]

(* Side at zero, then each field in turn at the values it is checked at *)
CheckedSide ==
    { ZeroSide }
        \cup { [ZeroSide EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Group Id: 2 bytes                                                       *)
(***************************************************************************)

GroupId2 ==
    [ groupId : Sample(2) ]

EncodeGroupId2(message) ==
    message.groupId

DecodeGroupId2(bytes) ==
    LET groupId == ReadBytes(bytes, 2) IN IF ~groupId.ok THEN Fail ELSE
    Ok([ groupId |-> groupId.value ], groupId.rest)

ZeroGroupId2 ==
    [ groupId |-> [i \in 1 .. 2 |-> 0] ]

(* Group Id at zero, then each field in turn at the values it is checked at *)
CheckedGroupId2 ==
    { ZeroGroupId2 }
        \cup { [ZeroGroupId2 EXCEPT !.groupId = one] : one \in Sample(2) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx14 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx14(message) ==
    message.userRefIdx

DecodeUserRefIdx14(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx14 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx14 ==
    { ZeroUserRefIdx14 }
        \cup { [ZeroUserRefIdx14 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Response Optional Value, selected by Mass Cancel Response   *)
(* Optional Field                                                          *)
(***************************************************************************)

SideCode == 27  \* 0x1b
GroupIdCode2 == 24  \* 0x18
UserRefIdxCode14 == 28  \* 0x1c

MassCancelResponseOptionalValue ==
    [ tag : {SideCode}, body : Side ]
        \cup [ tag : {GroupIdCode2}, body : GroupId2 ]
        \cup [ tag : {UserRefIdxCode14}, body : UserRefIdx14 ]

EncodeMassCancelResponseOptionalValue(message) ==
    CASE message.tag = SideCode -> EncodeSide(message.body)
      [] message.tag = GroupIdCode2 -> EncodeGroupId2(message.body)
      [] message.tag = UserRefIdxCode14 -> EncodeUserRefIdx14(message.body)

DecodeMassCancelResponseOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = SideCode -> DecodeSide(bytes)
              [] tag = GroupIdCode2 -> DecodeGroupId2(bytes)
              [] tag = UserRefIdxCode14 -> DecodeUserRefIdx14(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMassCancelResponseOptionalValue == [tag |-> SideCode, body |-> ZeroSide]

(* Each Mass Cancel Response Optional Value in turn, at the values the message it names is checked at *)
CheckedMassCancelResponseOptionalValue ==
    { [tag |-> SideCode, body |-> one] : one \in CheckedSide }
        \cup { [tag |-> GroupIdCode2, body |-> one] : one \in CheckedGroupId2 }
        \cup { [tag |-> UserRefIdxCode14, body |-> one] : one \in CheckedUserRefIdx14 }

(***************************************************************************)
(* Mass Cancel Response Appendage, framed by Optional Field Length         *)
(***************************************************************************)

MassCancelResponseAppendage ==
    [ massCancelResponseOptionalValue : MassCancelResponseOptionalValue ]

EncodeMassCancelResponseAppendageBody(message) ==
    EncodeUIntBE(message.massCancelResponseOptionalValue.tag, 1)
        \o EncodeMassCancelResponseOptionalValue(message.massCancelResponseOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeMassCancelResponseAppendage(message) ==
    LET body == EncodeMassCancelResponseAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeMassCancelResponseAppendageBody(bytes) ==
    LET massCancelResponseOptionalField == ReadUIntBE(bytes, 1) IN IF ~massCancelResponseOptionalField.ok THEN Fail ELSE
    LET massCancelResponseOptionalValue == DecodeMassCancelResponseOptionalValue(massCancelResponseOptionalField.value, massCancelResponseOptionalField.rest) IN IF ~massCancelResponseOptionalValue.ok THEN Fail ELSE
    Ok([ massCancelResponseOptionalValue |-> massCancelResponseOptionalValue.value ], massCancelResponseOptionalValue.rest)

DecodeMassCancelResponseAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMassCancelResponseAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMassCancelResponseAppendage ==
    [ massCancelResponseOptionalValue |-> ZeroMassCancelResponseOptionalValue ]

(* Mass Cancel Response Appendage at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelResponseAppendage ==
    { ZeroMassCancelResponseAppendage }
        \cup { [ZeroMassCancelResponseAppendage EXCEPT !.massCancelResponseOptionalValue = one] : one \in CheckedMassCancelResponseOptionalValue }

(* A run of Mass Cancel Response Appendage, written one after another *)
RECURSIVE EncodeMassCancelResponseAppendageList(_)
EncodeMassCancelResponseAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassCancelResponseAppendage(Head(messages)) \o EncodeMassCancelResponseAppendageList(Tail(messages))

(* As many Mass Cancel Response Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMassCancelResponseAppendageAll(_)
ReadMassCancelResponseAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMassCancelResponseAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassCancelResponseAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Cancel Response Appendage of each kind, for the lists that carry them *)
OneMassCancelResponseAppendage ==
    { [ZeroMassCancelResponseAppendage EXCEPT !.massCancelResponseOptionalValue = [tag |-> SideCode, body |-> ZeroSide]],
      [ZeroMassCancelResponseAppendage EXCEPT !.massCancelResponseOptionalValue = [tag |-> GroupIdCode2, body |-> ZeroGroupId2]],
      [ZeroMassCancelResponseAppendage EXCEPT !.massCancelResponseOptionalValue = [tag |-> UserRefIdxCode14, body |-> ZeroUserRefIdx14]] }

(***************************************************************************)
(* Mass Cancel Response Message                                            *)
(***************************************************************************)

MassCancelResponseMessage ==
    [ timestamp                   : Sample(8),
      userRefNum                  : Sample(4),
      firm                        : Sample(4),
      symbol                      : Sample(8),
      massCancelResponseAppendage : SampleLists(OneMassCancelResponseAppendage) ]

EncodeMassCancelResponseMessage(message) ==
    LET payload == EncodeMassCancelResponseAppendageList(message.massCancelResponseAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.firm
            \o message.symbol
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeMassCancelResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET firm == ReadBytes(userRefNum.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET symbol == ReadBytes(firm.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(symbol.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        massCancelResponseAppendage == ReadMassCancelResponseAppendageAll(framed)
    IN  IF ~massCancelResponseAppendage.ok \/ massCancelResponseAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         userRefNum                  |-> userRefNum.value,
         firm                        |-> firm.value,
         symbol                      |-> symbol.value,
         massCancelResponseAppendage |-> massCancelResponseAppendage.value ], beyond)

ZeroMassCancelResponseMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      userRefNum                  |-> [i \in 1 .. 4 |-> 0],
      firm                        |-> [i \in 1 .. 4 |-> 0],
      symbol                      |-> [i \in 1 .. 8 |-> 0],
      massCancelResponseAppendage |-> << >> ]

(* Mass Cancel Response Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelResponseMessage ==
    { ZeroMassCancelResponseMessage }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.massCancelResponseAppendage = one] : one \in SampleLists(OneMassCancelResponseAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx15 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx15(message) ==
    message.userRefIdx

DecodeUserRefIdx15(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx15 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx15 ==
    { ZeroUserRefIdx15 }
        \cup { [ZeroUserRefIdx15 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Disable Order Entry Response Optional Value, selected by Disable Order  *)
(* Entry Response Optional Field                                           *)
(***************************************************************************)

UserRefIdxCode15 == 28  \* 0x1c

DisableOrderEntryResponseOptionalValue ==
    [ tag : {UserRefIdxCode15}, body : UserRefIdx15 ]

EncodeDisableOrderEntryResponseOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode15 -> EncodeUserRefIdx15(message.body)

DecodeDisableOrderEntryResponseOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode15 -> DecodeUserRefIdx15(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroDisableOrderEntryResponseOptionalValue == [tag |-> UserRefIdxCode15, body |-> ZeroUserRefIdx15]

(* Each Disable Order Entry Response Optional Value in turn, at the values the message it names is checked at *)
CheckedDisableOrderEntryResponseOptionalValue ==
    { [tag |-> UserRefIdxCode15, body |-> one] : one \in CheckedUserRefIdx15 }

(***************************************************************************)
(* Disable Order Entry Response Appendage, framed by Optional Field Length *)
(***************************************************************************)

DisableOrderEntryResponseAppendage ==
    [ disableOrderEntryResponseOptionalValue : DisableOrderEntryResponseOptionalValue ]

EncodeDisableOrderEntryResponseAppendageBody(message) ==
    EncodeUIntBE(message.disableOrderEntryResponseOptionalValue.tag, 1)
        \o EncodeDisableOrderEntryResponseOptionalValue(message.disableOrderEntryResponseOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeDisableOrderEntryResponseAppendage(message) ==
    LET body == EncodeDisableOrderEntryResponseAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeDisableOrderEntryResponseAppendageBody(bytes) ==
    LET disableOrderEntryResponseOptionalField == ReadUIntBE(bytes, 1) IN IF ~disableOrderEntryResponseOptionalField.ok THEN Fail ELSE
    LET disableOrderEntryResponseOptionalValue == DecodeDisableOrderEntryResponseOptionalValue(disableOrderEntryResponseOptionalField.value, disableOrderEntryResponseOptionalField.rest) IN IF ~disableOrderEntryResponseOptionalValue.ok THEN Fail ELSE
    Ok([ disableOrderEntryResponseOptionalValue |-> disableOrderEntryResponseOptionalValue.value ], disableOrderEntryResponseOptionalValue.rest)

DecodeDisableOrderEntryResponseAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeDisableOrderEntryResponseAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroDisableOrderEntryResponseAppendage ==
    [ disableOrderEntryResponseOptionalValue |-> ZeroDisableOrderEntryResponseOptionalValue ]

(* Disable Order Entry Response Appendage at zero, then each field in turn at the values it is checked at *)
CheckedDisableOrderEntryResponseAppendage ==
    { ZeroDisableOrderEntryResponseAppendage }
        \cup { [ZeroDisableOrderEntryResponseAppendage EXCEPT !.disableOrderEntryResponseOptionalValue = one] : one \in CheckedDisableOrderEntryResponseOptionalValue }

(* A run of Disable Order Entry Response Appendage, written one after another *)
RECURSIVE EncodeDisableOrderEntryResponseAppendageList(_)
EncodeDisableOrderEntryResponseAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDisableOrderEntryResponseAppendage(Head(messages)) \o EncodeDisableOrderEntryResponseAppendageList(Tail(messages))

(* As many Disable Order Entry Response Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadDisableOrderEntryResponseAppendageAll(_)
ReadDisableOrderEntryResponseAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeDisableOrderEntryResponseAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDisableOrderEntryResponseAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Disable Order Entry Response Appendage of each kind, for the lists that carry them *)
OneDisableOrderEntryResponseAppendage ==
    { [ZeroDisableOrderEntryResponseAppendage EXCEPT !.disableOrderEntryResponseOptionalValue = [tag |-> UserRefIdxCode15, body |-> ZeroUserRefIdx15]] }

(***************************************************************************)
(* Disable Order Entry Response Message                                    *)
(***************************************************************************)

DisableOrderEntryResponseMessage ==
    [ timestamp                          : Sample(8),
      userRefNum                         : Sample(4),
      firm                               : Sample(4),
      disableOrderEntryResponseAppendage : SampleLists(OneDisableOrderEntryResponseAppendage) ]

EncodeDisableOrderEntryResponseMessage(message) ==
    LET payload == EncodeDisableOrderEntryResponseAppendageList(message.disableOrderEntryResponseAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.firm
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeDisableOrderEntryResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET firm == ReadBytes(userRefNum.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(firm.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        disableOrderEntryResponseAppendage == ReadDisableOrderEntryResponseAppendageAll(framed)
    IN  IF ~disableOrderEntryResponseAppendage.ok \/ disableOrderEntryResponseAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp                          |-> timestamp.value,
         userRefNum                         |-> userRefNum.value,
         firm                               |-> firm.value,
         disableOrderEntryResponseAppendage |-> disableOrderEntryResponseAppendage.value ], beyond)

ZeroDisableOrderEntryResponseMessage ==
    [ timestamp                          |-> [i \in 1 .. 8 |-> 0],
      userRefNum                         |-> [i \in 1 .. 4 |-> 0],
      firm                               |-> [i \in 1 .. 4 |-> 0],
      disableOrderEntryResponseAppendage |-> << >> ]

(* Disable Order Entry Response Message at zero, then each field in turn at the values it is checked at *)
CheckedDisableOrderEntryResponseMessage ==
    { ZeroDisableOrderEntryResponseMessage }
        \cup { [ZeroDisableOrderEntryResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroDisableOrderEntryResponseMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroDisableOrderEntryResponseMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroDisableOrderEntryResponseMessage EXCEPT !.disableOrderEntryResponseAppendage = one] : one \in SampleLists(OneDisableOrderEntryResponseAppendage) }

(***************************************************************************)
(* User Ref Idx: 1 bytes                                                   *)
(***************************************************************************)

UserRefIdx16 ==
    [ userRefIdx : Sample(1) ]

EncodeUserRefIdx16(message) ==
    message.userRefIdx

DecodeUserRefIdx16(bytes) ==
    LET userRefIdx == ReadBytes(bytes, 1) IN IF ~userRefIdx.ok THEN Fail ELSE
    Ok([ userRefIdx |-> userRefIdx.value ], userRefIdx.rest)

ZeroUserRefIdx16 ==
    [ userRefIdx |-> [i \in 1 .. 1 |-> 0] ]

(* User Ref Idx at zero, then each field in turn at the values it is checked at *)
CheckedUserRefIdx16 ==
    { ZeroUserRefIdx16 }
        \cup { [ZeroUserRefIdx16 EXCEPT !.userRefIdx = one] : one \in Sample(1) }

(***************************************************************************)
(* Enable Order Entry Response Optional Value, selected by Enable Order    *)
(* Entry Response Optional Field                                           *)
(***************************************************************************)

UserRefIdxCode16 == 28  \* 0x1c

EnableOrderEntryResponseOptionalValue ==
    [ tag : {UserRefIdxCode16}, body : UserRefIdx16 ]

EncodeEnableOrderEntryResponseOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode16 -> EncodeUserRefIdx16(message.body)

DecodeEnableOrderEntryResponseOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode16 -> DecodeUserRefIdx16(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroEnableOrderEntryResponseOptionalValue == [tag |-> UserRefIdxCode16, body |-> ZeroUserRefIdx16]

(* Each Enable Order Entry Response Optional Value in turn, at the values the message it names is checked at *)
CheckedEnableOrderEntryResponseOptionalValue ==
    { [tag |-> UserRefIdxCode16, body |-> one] : one \in CheckedUserRefIdx16 }

(***************************************************************************)
(* Enable Order Entry Response Appendage, framed by Optional Field Length  *)
(***************************************************************************)

EnableOrderEntryResponseAppendage ==
    [ enableOrderEntryResponseOptionalValue : EnableOrderEntryResponseOptionalValue ]

EncodeEnableOrderEntryResponseAppendageBody(message) ==
    EncodeUIntBE(message.enableOrderEntryResponseOptionalValue.tag, 1)
        \o EncodeEnableOrderEntryResponseOptionalValue(message.enableOrderEntryResponseOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeEnableOrderEntryResponseAppendage(message) ==
    LET body == EncodeEnableOrderEntryResponseAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeEnableOrderEntryResponseAppendageBody(bytes) ==
    LET enableOrderEntryResponseOptionalField == ReadUIntBE(bytes, 1) IN IF ~enableOrderEntryResponseOptionalField.ok THEN Fail ELSE
    LET enableOrderEntryResponseOptionalValue == DecodeEnableOrderEntryResponseOptionalValue(enableOrderEntryResponseOptionalField.value, enableOrderEntryResponseOptionalField.rest) IN IF ~enableOrderEntryResponseOptionalValue.ok THEN Fail ELSE
    Ok([ enableOrderEntryResponseOptionalValue |-> enableOrderEntryResponseOptionalValue.value ], enableOrderEntryResponseOptionalValue.rest)

DecodeEnableOrderEntryResponseAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeEnableOrderEntryResponseAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroEnableOrderEntryResponseAppendage ==
    [ enableOrderEntryResponseOptionalValue |-> ZeroEnableOrderEntryResponseOptionalValue ]

(* Enable Order Entry Response Appendage at zero, then each field in turn at the values it is checked at *)
CheckedEnableOrderEntryResponseAppendage ==
    { ZeroEnableOrderEntryResponseAppendage }
        \cup { [ZeroEnableOrderEntryResponseAppendage EXCEPT !.enableOrderEntryResponseOptionalValue = one] : one \in CheckedEnableOrderEntryResponseOptionalValue }

(* A run of Enable Order Entry Response Appendage, written one after another *)
RECURSIVE EncodeEnableOrderEntryResponseAppendageList(_)
EncodeEnableOrderEntryResponseAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEnableOrderEntryResponseAppendage(Head(messages)) \o EncodeEnableOrderEntryResponseAppendageList(Tail(messages))

(* As many Enable Order Entry Response Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadEnableOrderEntryResponseAppendageAll(_)
ReadEnableOrderEntryResponseAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeEnableOrderEntryResponseAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEnableOrderEntryResponseAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Enable Order Entry Response Appendage of each kind, for the lists that carry them *)
OneEnableOrderEntryResponseAppendage ==
    { [ZeroEnableOrderEntryResponseAppendage EXCEPT !.enableOrderEntryResponseOptionalValue = [tag |-> UserRefIdxCode16, body |-> ZeroUserRefIdx16]] }

(***************************************************************************)
(* Enable Order Entry Response Message                                     *)
(***************************************************************************)

EnableOrderEntryResponseMessage ==
    [ timestamp                         : Sample(8),
      userRefNum                        : Sample(4),
      firm                              : Sample(4),
      enableOrderEntryResponseAppendage : SampleLists(OneEnableOrderEntryResponseAppendage) ]

EncodeEnableOrderEntryResponseMessage(message) ==
    LET payload == EncodeEnableOrderEntryResponseAppendageList(message.enableOrderEntryResponseAppendage)
    IN  message.timestamp
            \o message.userRefNum
            \o message.firm
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeEnableOrderEntryResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET firm == ReadBytes(userRefNum.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(firm.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        enableOrderEntryResponseAppendage == ReadEnableOrderEntryResponseAppendageAll(framed)
    IN  IF ~enableOrderEntryResponseAppendage.ok \/ enableOrderEntryResponseAppendage.rest # << >> THEN Fail ELSE
    Ok([ timestamp                         |-> timestamp.value,
         userRefNum                        |-> userRefNum.value,
         firm                              |-> firm.value,
         enableOrderEntryResponseAppendage |-> enableOrderEntryResponseAppendage.value ], beyond)

ZeroEnableOrderEntryResponseMessage ==
    [ timestamp                         |-> [i \in 1 .. 8 |-> 0],
      userRefNum                        |-> [i \in 1 .. 4 |-> 0],
      firm                              |-> [i \in 1 .. 4 |-> 0],
      enableOrderEntryResponseAppendage |-> << >> ]

(* Enable Order Entry Response Message at zero, then each field in turn at the values it is checked at *)
CheckedEnableOrderEntryResponseMessage ==
    { ZeroEnableOrderEntryResponseMessage }
        \cup { [ZeroEnableOrderEntryResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroEnableOrderEntryResponseMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroEnableOrderEntryResponseMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroEnableOrderEntryResponseMessage EXCEPT !.enableOrderEntryResponseAppendage = one] : one \in SampleLists(OneEnableOrderEntryResponseAppendage) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OrderAcceptedMessageCode == 65  \* "A"
ReplacedMessageCode == 85  \* "U"
CanceledMessageCode == 67  \* "C"
AiqCanceledMessageCode == 68  \* "D"
OrderExecutedMessageCode == 69  \* "E"
BrokenTradeMessageCode == 66  \* "B"
RejectedOrderMessageCode == 74  \* "J"
CancelPendingMessageCode == 80  \* "P"
CancelRejectMessageCode == 73  \* "I"
OrderPriorityUpdateMessageCode == 84  \* "T"
OrderModifiedMessageCode == 77  \* "M"
OrderRestatedMessageCode == 82  \* "R"
AccountQueryResponseMessageCode == 81  \* "Q"
MassCancelResponseMessageCode == 88  \* "X"
DisableOrderEntryResponseMessageCode == 71  \* "G"
EnableOrderEntryResponseMessageCode == 75  \* "K"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderAcceptedMessageCode}, body : OrderAcceptedMessage ]
        \cup [ tag : {ReplacedMessageCode}, body : ReplacedMessage ]
        \cup [ tag : {CanceledMessageCode}, body : CanceledMessage ]
        \cup [ tag : {AiqCanceledMessageCode}, body : AiqCanceledMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {RejectedOrderMessageCode}, body : RejectedOrderMessage ]
        \cup [ tag : {CancelPendingMessageCode}, body : CancelPendingMessage ]
        \cup [ tag : {CancelRejectMessageCode}, body : CancelRejectMessage ]
        \cup [ tag : {OrderPriorityUpdateMessageCode}, body : OrderPriorityUpdateMessage ]
        \cup [ tag : {OrderModifiedMessageCode}, body : OrderModifiedMessage ]
        \cup [ tag : {OrderRestatedMessageCode}, body : OrderRestatedMessage ]
        \cup [ tag : {AccountQueryResponseMessageCode}, body : AccountQueryResponseMessage ]
        \cup [ tag : {MassCancelResponseMessageCode}, body : MassCancelResponseMessage ]
        \cup [ tag : {DisableOrderEntryResponseMessageCode}, body : DisableOrderEntryResponseMessage ]
        \cup [ tag : {EnableOrderEntryResponseMessageCode}, body : EnableOrderEntryResponseMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderAcceptedMessageCode -> EncodeOrderAcceptedMessage(message.body)
      [] message.tag = ReplacedMessageCode -> EncodeReplacedMessage(message.body)
      [] message.tag = CanceledMessageCode -> EncodeCanceledMessage(message.body)
      [] message.tag = AiqCanceledMessageCode -> EncodeAiqCanceledMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = RejectedOrderMessageCode -> EncodeRejectedOrderMessage(message.body)
      [] message.tag = CancelPendingMessageCode -> EncodeCancelPendingMessage(message.body)
      [] message.tag = CancelRejectMessageCode -> EncodeCancelRejectMessage(message.body)
      [] message.tag = OrderPriorityUpdateMessageCode -> EncodeOrderPriorityUpdateMessage(message.body)
      [] message.tag = OrderModifiedMessageCode -> EncodeOrderModifiedMessage(message.body)
      [] message.tag = OrderRestatedMessageCode -> EncodeOrderRestatedMessage(message.body)
      [] message.tag = AccountQueryResponseMessageCode -> EncodeAccountQueryResponseMessage(message.body)
      [] message.tag = MassCancelResponseMessageCode -> EncodeMassCancelResponseMessage(message.body)
      [] message.tag = DisableOrderEntryResponseMessageCode -> EncodeDisableOrderEntryResponseMessage(message.body)
      [] message.tag = EnableOrderEntryResponseMessageCode -> EncodeEnableOrderEntryResponseMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderAcceptedMessageCode -> DecodeOrderAcceptedMessage(bytes)
              [] tag = ReplacedMessageCode -> DecodeReplacedMessage(bytes)
              [] tag = CanceledMessageCode -> DecodeCanceledMessage(bytes)
              [] tag = AiqCanceledMessageCode -> DecodeAiqCanceledMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = RejectedOrderMessageCode -> DecodeRejectedOrderMessage(bytes)
              [] tag = CancelPendingMessageCode -> DecodeCancelPendingMessage(bytes)
              [] tag = CancelRejectMessageCode -> DecodeCancelRejectMessage(bytes)
              [] tag = OrderPriorityUpdateMessageCode -> DecodeOrderPriorityUpdateMessage(bytes)
              [] tag = OrderModifiedMessageCode -> DecodeOrderModifiedMessage(bytes)
              [] tag = OrderRestatedMessageCode -> DecodeOrderRestatedMessage(bytes)
              [] tag = AccountQueryResponseMessageCode -> DecodeAccountQueryResponseMessage(bytes)
              [] tag = MassCancelResponseMessageCode -> DecodeMassCancelResponseMessage(bytes)
              [] tag = DisableOrderEntryResponseMessageCode -> DecodeDisableOrderEntryResponseMessage(bytes)
              [] tag = EnableOrderEntryResponseMessageCode -> DecodeEnableOrderEntryResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderAcceptedMessageCode, body |-> one] : one \in CheckedOrderAcceptedMessage }
        \cup { [tag |-> ReplacedMessageCode, body |-> one] : one \in CheckedReplacedMessage }
        \cup { [tag |-> CanceledMessageCode, body |-> one] : one \in CheckedCanceledMessage }
        \cup { [tag |-> AiqCanceledMessageCode, body |-> one] : one \in CheckedAiqCanceledMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> RejectedOrderMessageCode, body |-> one] : one \in CheckedRejectedOrderMessage }
        \cup { [tag |-> CancelPendingMessageCode, body |-> one] : one \in CheckedCancelPendingMessage }
        \cup { [tag |-> CancelRejectMessageCode, body |-> one] : one \in CheckedCancelRejectMessage }
        \cup { [tag |-> OrderPriorityUpdateMessageCode, body |-> one] : one \in CheckedOrderPriorityUpdateMessage }
        \cup { [tag |-> OrderModifiedMessageCode, body |-> one] : one \in CheckedOrderModifiedMessage }
        \cup { [tag |-> OrderRestatedMessageCode, body |-> one] : one \in CheckedOrderRestatedMessage }
        \cup { [tag |-> AccountQueryResponseMessageCode, body |-> one] : one \in CheckedAccountQueryResponseMessage }
        \cup { [tag |-> MassCancelResponseMessageCode, body |-> one] : one \in CheckedMassCancelResponseMessage }
        \cup { [tag |-> DisableOrderEntryResponseMessageCode, body |-> one] : one \in CheckedDisableOrderEntryResponseMessage }
        \cup { [tag |-> EnableOrderEntryResponseMessageCode, body |-> one] : one \in CheckedEnableOrderEntryResponseMessage }

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

(* Every Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripFirm ==
    \A message \in CheckedFirm :
        LET read == DecodeFirm(EncodeFirm(message))
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

(* Every Customer Type decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomerType ==
    \A message \in CheckedCustomerType :
        LET read == DecodeCustomerType(EncodeCustomerType(message))
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

(* Every Price Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceType ==
    \A message \in CheckedPriceType :
        LET read == DecodePriceType(EncodePriceType(message))
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

(* Every Discretion Price decodes back to what was encoded, and leaves nothing over *)
RoundTripDiscretionPrice ==
    \A message \in CheckedDiscretionPrice :
        LET read == DecodeDiscretionPrice(EncodeDiscretionPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Discretion Price Type decodes back to what was encoded, and leaves nothing over *)
RoundTripDiscretionPriceType ==
    \A message \in CheckedDiscretionPriceType :
        LET read == DecodeDiscretionPriceType(EncodeDiscretionPriceType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Discretion Peg Offset decodes back to what was encoded, and leaves nothing over *)
RoundTripDiscretionPegOffset ==
    \A message \in CheckedDiscretionPegOffset :
        LET read == DecodeDiscretionPegOffset(EncodeDiscretionPegOffset(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Post Only decodes back to what was encoded, and leaves nothing over *)
RoundTripPostOnly ==
    \A message \in CheckedPostOnly :
        LET read == DecodePostOnly(EncodePostOnly(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Random Reserves decodes back to what was encoded, and leaves nothing over *)
RoundTripRandomReserves ==
    \A message \in CheckedRandomReserves :
        LET read == DecodeRandomReserves(EncodeRandomReserves(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Route decodes back to what was encoded, and leaves nothing over *)
RoundTripRoute ==
    \A message \in CheckedRoute :
        LET read == DecodeRoute(EncodeRoute(message))
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

(* Every Trade Now decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeNow ==
    \A message \in CheckedTradeNow :
        LET read == DecodeTradeNow(EncodeTradeNow(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Handle Inst decodes back to what was encoded, and leaves nothing over *)
RoundTripHandleInst ==
    \A message \in CheckedHandleInst :
        LET read == DecodeHandleInst(EncodeHandleInst(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bbo Weight Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripBboWeightIndicator ==
    \A message \in CheckedBboWeightIndicator :
        LET read == DecodeBboWeightIndicator(EncodeBboWeightIndicator(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Group Id decodes back to what was encoded, and leaves nothing over *)
RoundTripGroupId ==
    \A message \in CheckedGroupId :
        LET read == DecodeGroupId(EncodeGroupId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Shares Located decodes back to what was encoded, and leaves nothing over *)
RoundTripSharesLocated ==
    \A message \in CheckedSharesLocated :
        LET read == DecodeSharesLocated(EncodeSharesLocated(message))
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

(* Every Aiq Strategy decodes back to what was encoded, and leaves nothing over *)
RoundTripAiqStrategy ==
    \A message \in CheckedAiqStrategy :
        LET read == DecodeAiqStrategy(EncodeAiqStrategy(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aiq Group Id decodes back to what was encoded, and leaves nothing over *)
RoundTripAiqGroupId ==
    \A message \in CheckedAiqGroupId :
        LET read == DecodeAiqGroupId(EncodeAiqGroupId(message))
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

(* Every Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripFirm2 ==
    \A message \in CheckedFirm2 :
        LET read == DecodeFirm2(EncodeFirm2(message))
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

(* Every Price Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceType2 ==
    \A message \in CheckedPriceType2 :
        LET read == DecodePriceType2(EncodePriceType2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Post Only decodes back to what was encoded, and leaves nothing over *)
RoundTripPostOnly2 ==
    \A message \in CheckedPostOnly2 :
        LET read == DecodePostOnly2(EncodePostOnly2(message))
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

(* Every Trade Now decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeNow2 ==
    \A message \in CheckedTradeNow2 :
        LET read == DecodeTradeNow2(EncodeTradeNow2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Handle Inst decodes back to what was encoded, and leaves nothing over *)
RoundTripHandleInst2 ==
    \A message \in CheckedHandleInst2 :
        LET read == DecodeHandleInst2(EncodeHandleInst2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bbo Weight Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripBboWeightIndicator2 ==
    \A message \in CheckedBboWeightIndicator2 :
        LET read == DecodeBboWeightIndicator2(EncodeBboWeightIndicator2(message))
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

(* Every Aiq Strategy decodes back to what was encoded, and leaves nothing over *)
RoundTripAiqStrategy2 ==
    \A message \in CheckedAiqStrategy2 :
        LET read == DecodeAiqStrategy2(EncodeAiqStrategy2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aiq Group Id decodes back to what was encoded, and leaves nothing over *)
RoundTripAiqGroupId2 ==
    \A message \in CheckedAiqGroupId2 :
        LET read == DecodeAiqGroupId2(EncodeAiqGroupId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replaced Message Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripReplacedMessageAppendage ==
    \A message \in CheckedReplacedMessageAppendage :
        LET read == DecodeReplacedMessageAppendage(EncodeReplacedMessageAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplacedMessage ==
    \A message \in CheckedReplacedMessage :
        LET read == DecodeReplacedMessage(EncodeReplacedMessage(message))
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

(* Every Canceled Message Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripCanceledMessageAppendage ==
    \A message \in CheckedCanceledMessageAppendage :
        LET read == DecodeCanceledMessageAppendage(EncodeCanceledMessageAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCanceledMessageTail ==
    \A message \in CheckedCanceledMessageTail :
        LET read == DecodeCanceledMessageTail(EncodeCanceledMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCanceledMessage ==
    \A message \in CheckedCanceledMessage :
        LET read == DecodeCanceledMessage(EncodeCanceledMessage(message))
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

(* Every Aiq Canceled Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripAiqCanceledAppendage ==
    \A message \in CheckedAiqCanceledAppendage :
        LET read == DecodeAiqCanceledAppendage(EncodeAiqCanceledAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aiq Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAiqCanceledMessageTail ==
    \A message \in CheckedAiqCanceledMessageTail :
        LET read == DecodeAiqCanceledMessageTail(EncodeAiqCanceledMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aiq Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAiqCanceledMessage ==
    \A message \in CheckedAiqCanceledMessage :
        LET read == DecodeAiqCanceledMessage(EncodeAiqCanceledMessage(message))
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

(* Every Broken Trade Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeAppendage ==
    \A message \in CheckedBrokenTradeAppendage :
        LET read == DecodeBrokenTradeAppendage(EncodeBrokenTradeAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessageTail ==
    \A message \in CheckedBrokenTradeMessageTail :
        LET read == DecodeBrokenTradeMessageTail(EncodeBrokenTradeMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
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
RoundTripRejectedOrderMessageTail ==
    \A message \in CheckedRejectedOrderMessageTail :
        LET read == DecodeRejectedOrderMessageTail(EncodeRejectedOrderMessageTail(message))
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

(* Every Cancel Pending Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelPendingAppendage ==
    \A message \in CheckedCancelPendingAppendage :
        LET read == DecodeCancelPendingAppendage(EncodeCancelPendingAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Pending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelPendingMessageTail ==
    \A message \in CheckedCancelPendingMessageTail :
        LET read == DecodeCancelPendingMessageTail(EncodeCancelPendingMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Pending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelPendingMessage ==
    \A message \in CheckedCancelPendingMessage :
        LET read == DecodeCancelPendingMessage(EncodeCancelPendingMessage(message))
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

(* Every Cancel Reject Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectAppendage ==
    \A message \in CheckedCancelRejectAppendage :
        LET read == DecodeCancelRejectAppendage(EncodeCancelRejectAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectMessageTail ==
    \A message \in CheckedCancelRejectMessageTail :
        LET read == DecodeCancelRejectMessageTail(EncodeCancelRejectMessageTail(message))
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
RoundTripUserRefIdx10 ==
    \A message \in CheckedUserRefIdx10 :
        LET read == DecodeUserRefIdx10(EncodeUserRefIdx10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Priority Update Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPriorityUpdateAppendage ==
    \A message \in CheckedOrderPriorityUpdateAppendage :
        LET read == DecodeOrderPriorityUpdateAppendage(EncodeOrderPriorityUpdateAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Priority Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPriorityUpdateMessageTail ==
    \A message \in CheckedOrderPriorityUpdateMessageTail :
        LET read == DecodeOrderPriorityUpdateMessageTail(EncodeOrderPriorityUpdateMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Priority Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPriorityUpdateMessage ==
    \A message \in CheckedOrderPriorityUpdateMessage :
        LET read == DecodeOrderPriorityUpdateMessage(EncodeOrderPriorityUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx11 ==
    \A message \in CheckedUserRefIdx11 :
        LET read == DecodeUserRefIdx11(EncodeUserRefIdx11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Shares Located decodes back to what was encoded, and leaves nothing over *)
RoundTripSharesLocated2 ==
    \A message \in CheckedSharesLocated2 :
        LET read == DecodeSharesLocated2(EncodeSharesLocated2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Locate Broker decodes back to what was encoded, and leaves nothing over *)
RoundTripLocateBroker ==
    \A message \in CheckedLocateBroker :
        LET read == DecodeLocateBroker(EncodeLocateBroker(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedAppendage ==
    \A message \in CheckedOrderModifiedAppendage :
        LET read == DecodeOrderModifiedAppendage(EncodeOrderModifiedAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedMessageTail ==
    \A message \in CheckedOrderModifiedMessageTail :
        LET read == DecodeOrderModifiedMessageTail(EncodeOrderModifiedMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modified Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifiedMessage ==
    \A message \in CheckedOrderModifiedMessage :
        LET read == DecodeOrderModifiedMessage(EncodeOrderModifiedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayQuantity ==
    \A message \in CheckedDisplayQuantity :
        LET read == DecodeDisplayQuantity(EncodeDisplayQuantity(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Price decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayPrice ==
    \A message \in CheckedDisplayPrice :
        LET read == DecodeDisplayPrice(EncodeDisplayPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Ord Ref Num decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryOrdRefNum ==
    \A message \in CheckedSecondaryOrdRefNum :
        LET read == DecodeSecondaryOrdRefNum(EncodeSecondaryOrdRefNum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx12 ==
    \A message \in CheckedUserRefIdx12 :
        LET read == DecodeUserRefIdx12(EncodeUserRefIdx12(message))
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
RoundTripUserRefIdx13 ==
    \A message \in CheckedUserRefIdx13 :
        LET read == DecodeUserRefIdx13(EncodeUserRefIdx13(message))
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

(* Every Side decodes back to what was encoded, and leaves nothing over *)
RoundTripSide ==
    \A message \in CheckedSide :
        LET read == DecodeSide(EncodeSide(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Group Id decodes back to what was encoded, and leaves nothing over *)
RoundTripGroupId2 ==
    \A message \in CheckedGroupId2 :
        LET read == DecodeGroupId2(EncodeGroupId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx14 ==
    \A message \in CheckedUserRefIdx14 :
        LET read == DecodeUserRefIdx14(EncodeUserRefIdx14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Response Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelResponseAppendage ==
    \A message \in CheckedMassCancelResponseAppendage :
        LET read == DecodeMassCancelResponseAppendage(EncodeMassCancelResponseAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelResponseMessage ==
    \A message \in CheckedMassCancelResponseMessage :
        LET read == DecodeMassCancelResponseMessage(EncodeMassCancelResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx15 ==
    \A message \in CheckedUserRefIdx15 :
        LET read == DecodeUserRefIdx15(EncodeUserRefIdx15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disable Order Entry Response Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripDisableOrderEntryResponseAppendage ==
    \A message \in CheckedDisableOrderEntryResponseAppendage :
        LET read == DecodeDisableOrderEntryResponseAppendage(EncodeDisableOrderEntryResponseAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disable Order Entry Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDisableOrderEntryResponseMessage ==
    \A message \in CheckedDisableOrderEntryResponseMessage :
        LET read == DecodeDisableOrderEntryResponseMessage(EncodeDisableOrderEntryResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ref Idx decodes back to what was encoded, and leaves nothing over *)
RoundTripUserRefIdx16 ==
    \A message \in CheckedUserRefIdx16 :
        LET read == DecodeUserRefIdx16(EncodeUserRefIdx16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enable Order Entry Response Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripEnableOrderEntryResponseAppendage ==
    \A message \in CheckedEnableOrderEntryResponseAppendage :
        LET read == DecodeEnableOrderEntryResponseAppendage(EncodeEnableOrderEntryResponseAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enable Order Entry Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEnableOrderEntryResponseMessage ==
    \A message \in CheckedEnableOrderEntryResponseMessage :
        LET read == DecodeEnableOrderEntryResponseMessage(EncodeEnableOrderEntryResponseMessage(message))
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

(* A Replaced Message Optional Value is selected by the Replaced Message Optional Field it is written under *)
SelectsReplacedMessageOptionalValue ==
    \A message \in CheckedReplacedMessageOptionalValue :
        LET read == DecodeReplacedMessageOptionalValue(message.tag, EncodeReplacedMessageOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Canceled Message Optional Value is selected by the Canceled Message Optional Field it is written under *)
SelectsCanceledMessageOptionalValue ==
    \A message \in CheckedCanceledMessageOptionalValue :
        LET read == DecodeCanceledMessageOptionalValue(message.tag, EncodeCanceledMessageOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Aiq Canceled Optional Value is selected by the Aiq Canceled Optional Field it is written under *)
SelectsAiqCanceledOptionalValue ==
    \A message \in CheckedAiqCanceledOptionalValue :
        LET read == DecodeAiqCanceledOptionalValue(message.tag, EncodeAiqCanceledOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Order Executed Optional Value is selected by the Order Executed Optional Field it is written under *)
SelectsOrderExecutedOptionalValue ==
    \A message \in CheckedOrderExecutedOptionalValue :
        LET read == DecodeOrderExecutedOptionalValue(message.tag, EncodeOrderExecutedOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Broken Trade Optional Value is selected by the Broken Trade Optional Field it is written under *)
SelectsBrokenTradeOptionalValue ==
    \A message \in CheckedBrokenTradeOptionalValue :
        LET read == DecodeBrokenTradeOptionalValue(message.tag, EncodeBrokenTradeOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Rejected Order Optional Value is selected by the Rejected Order Optional Field it is written under *)
SelectsRejectedOrderOptionalValue ==
    \A message \in CheckedRejectedOrderOptionalValue :
        LET read == DecodeRejectedOrderOptionalValue(message.tag, EncodeRejectedOrderOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Cancel Pending Optional Value is selected by the Cancel Pending Optional Field it is written under *)
SelectsCancelPendingOptionalValue ==
    \A message \in CheckedCancelPendingOptionalValue :
        LET read == DecodeCancelPendingOptionalValue(message.tag, EncodeCancelPendingOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Cancel Reject Optional Value is selected by the Cancel Reject Optional Field it is written under *)
SelectsCancelRejectOptionalValue ==
    \A message \in CheckedCancelRejectOptionalValue :
        LET read == DecodeCancelRejectOptionalValue(message.tag, EncodeCancelRejectOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Order Priority Update Optional Value is selected by the Order Priority Update Optional Field it is written under *)
SelectsOrderPriorityUpdateOptionalValue ==
    \A message \in CheckedOrderPriorityUpdateOptionalValue :
        LET read == DecodeOrderPriorityUpdateOptionalValue(message.tag, EncodeOrderPriorityUpdateOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Order Modified Optional Value is selected by the Order Modified Optional Field it is written under *)
SelectsOrderModifiedOptionalValue ==
    \A message \in CheckedOrderModifiedOptionalValue :
        LET read == DecodeOrderModifiedOptionalValue(message.tag, EncodeOrderModifiedOptionalValue(message))
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

(* A Mass Cancel Response Optional Value is selected by the Mass Cancel Response Optional Field it is written under *)
SelectsMassCancelResponseOptionalValue ==
    \A message \in CheckedMassCancelResponseOptionalValue :
        LET read == DecodeMassCancelResponseOptionalValue(message.tag, EncodeMassCancelResponseOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Disable Order Entry Response Optional Value is selected by the Disable Order Entry Response Optional Field it is written under *)
SelectsDisableOrderEntryResponseOptionalValue ==
    \A message \in CheckedDisableOrderEntryResponseOptionalValue :
        LET read == DecodeDisableOrderEntryResponseOptionalValue(message.tag, EncodeDisableOrderEntryResponseOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Enable Order Entry Response Optional Value is selected by the Enable Order Entry Response Optional Field it is written under *)
SelectsEnableOrderEntryResponseOptionalValue ==
    \A message \in CheckedEnableOrderEntryResponseOptionalValue :
        LET read == DecodeEnableOrderEntryResponseOptionalValue(message.tag, EncodeEnableOrderEntryResponseOptionalValue(message))
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
FramesReplacedMessageAppendage ==
    \A message \in CheckedReplacedMessageAppendage :
        LET bytes == EncodeReplacedMessageAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesCanceledMessageAppendage ==
    \A message \in CheckedCanceledMessageAppendage :
        LET bytes == EncodeCanceledMessageAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesAiqCanceledAppendage ==
    \A message \in CheckedAiqCanceledAppendage :
        LET bytes == EncodeAiqCanceledAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesOrderExecutedAppendage ==
    \A message \in CheckedOrderExecutedAppendage :
        LET bytes == EncodeOrderExecutedAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesBrokenTradeAppendage ==
    \A message \in CheckedBrokenTradeAppendage :
        LET bytes == EncodeBrokenTradeAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesRejectedOrderAppendage ==
    \A message \in CheckedRejectedOrderAppendage :
        LET bytes == EncodeRejectedOrderAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesCancelPendingAppendage ==
    \A message \in CheckedCancelPendingAppendage :
        LET bytes == EncodeCancelPendingAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesCancelRejectAppendage ==
    \A message \in CheckedCancelRejectAppendage :
        LET bytes == EncodeCancelRejectAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesOrderPriorityUpdateAppendage ==
    \A message \in CheckedOrderPriorityUpdateAppendage :
        LET bytes == EncodeOrderPriorityUpdateAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesOrderModifiedAppendage ==
    \A message \in CheckedOrderModifiedAppendage :
        LET bytes == EncodeOrderModifiedAppendage(message)
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

(* Optional Field Length is written from the bytes it frames *)
FramesMassCancelResponseAppendage ==
    \A message \in CheckedMassCancelResponseAppendage :
        LET bytes == EncodeMassCancelResponseAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesDisableOrderEntryResponseAppendage ==
    \A message \in CheckedDisableOrderEntryResponseAppendage :
        LET bytes == EncodeDisableOrderEntryResponseAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesEnableOrderEntryResponseAppendage ==
    \A message \in CheckedEnableOrderEntryResponseAppendage :
        LET bytes == EncodeEnableOrderEntryResponseAppendage(message)
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
