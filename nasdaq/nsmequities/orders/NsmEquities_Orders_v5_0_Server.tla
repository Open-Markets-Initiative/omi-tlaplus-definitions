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
(* Discretion Peg Type: 1 bytes                                            *)
(***************************************************************************)

DiscretionPegType ==
    [ discretionPegType : Sample(1) ]

EncodeDiscretionPegType(message) ==
    message.discretionPegType

DecodeDiscretionPegType(bytes) ==
    LET discretionPegType == ReadBytes(bytes, 1) IN IF ~discretionPegType.ok THEN Fail ELSE
    Ok([ discretionPegType |-> discretionPegType.value ], discretionPegType.rest)

ZeroDiscretionPegType ==
    [ discretionPegType |-> [i \in 1 .. 1 |-> 0] ]

(* Discretion Peg Type at zero, then each field in turn at the values it is checked at *)
CheckedDiscretionPegType ==
    { ZeroDiscretionPegType }
        \cup { [ZeroDiscretionPegType EXCEPT !.discretionPegType = one] : one \in Sample(1) }

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
DiscretionPegTypeCode == 10  \* 0x0a
DiscretionPegOffsetCode == 11  \* 0x0b
PostOnlyCode == 12  \* 0x0c
RandomReservesCode == 13  \* 0x0d
RouteCode == 14  \* 0x0e
ExpireTimeCode == 15  \* 0x0f
TradeNowCode == 16  \* 0x10
HandleInstCode == 17  \* 0x11
BboWeightIndicatorCode == 18  \* 0x12

OrderAcceptedOptionalValue ==
    [ tag : {FirmCode}, body : Firm ]
        \cup [ tag : {MinQtyCode}, body : MinQty ]
        \cup [ tag : {CustomerTypeCode}, body : CustomerType ]
        \cup [ tag : {MaxFloorCode}, body : MaxFloor ]
        \cup [ tag : {PriceTypeCode}, body : PriceType ]
        \cup [ tag : {PegOffsetCode}, body : PegOffset ]
        \cup [ tag : {DiscretionPriceCode}, body : DiscretionPrice ]
        \cup [ tag : {DiscretionPegTypeCode}, body : DiscretionPegType ]
        \cup [ tag : {DiscretionPegOffsetCode}, body : DiscretionPegOffset ]
        \cup [ tag : {PostOnlyCode}, body : PostOnly ]
        \cup [ tag : {RandomReservesCode}, body : RandomReserves ]
        \cup [ tag : {RouteCode}, body : Route ]
        \cup [ tag : {ExpireTimeCode}, body : ExpireTime ]
        \cup [ tag : {TradeNowCode}, body : TradeNow ]
        \cup [ tag : {HandleInstCode}, body : HandleInst ]
        \cup [ tag : {BboWeightIndicatorCode}, body : BboWeightIndicator ]

EncodeOrderAcceptedOptionalValue(message) ==
    CASE message.tag = FirmCode -> EncodeFirm(message.body)
      [] message.tag = MinQtyCode -> EncodeMinQty(message.body)
      [] message.tag = CustomerTypeCode -> EncodeCustomerType(message.body)
      [] message.tag = MaxFloorCode -> EncodeMaxFloor(message.body)
      [] message.tag = PriceTypeCode -> EncodePriceType(message.body)
      [] message.tag = PegOffsetCode -> EncodePegOffset(message.body)
      [] message.tag = DiscretionPriceCode -> EncodeDiscretionPrice(message.body)
      [] message.tag = DiscretionPegTypeCode -> EncodeDiscretionPegType(message.body)
      [] message.tag = DiscretionPegOffsetCode -> EncodeDiscretionPegOffset(message.body)
      [] message.tag = PostOnlyCode -> EncodePostOnly(message.body)
      [] message.tag = RandomReservesCode -> EncodeRandomReserves(message.body)
      [] message.tag = RouteCode -> EncodeRoute(message.body)
      [] message.tag = ExpireTimeCode -> EncodeExpireTime(message.body)
      [] message.tag = TradeNowCode -> EncodeTradeNow(message.body)
      [] message.tag = HandleInstCode -> EncodeHandleInst(message.body)
      [] message.tag = BboWeightIndicatorCode -> EncodeBboWeightIndicator(message.body)

DecodeOrderAcceptedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = FirmCode -> DecodeFirm(bytes)
              [] tag = MinQtyCode -> DecodeMinQty(bytes)
              [] tag = CustomerTypeCode -> DecodeCustomerType(bytes)
              [] tag = MaxFloorCode -> DecodeMaxFloor(bytes)
              [] tag = PriceTypeCode -> DecodePriceType(bytes)
              [] tag = PegOffsetCode -> DecodePegOffset(bytes)
              [] tag = DiscretionPriceCode -> DecodeDiscretionPrice(bytes)
              [] tag = DiscretionPegTypeCode -> DecodeDiscretionPegType(bytes)
              [] tag = DiscretionPegOffsetCode -> DecodeDiscretionPegOffset(bytes)
              [] tag = PostOnlyCode -> DecodePostOnly(bytes)
              [] tag = RandomReservesCode -> DecodeRandomReserves(bytes)
              [] tag = RouteCode -> DecodeRoute(bytes)
              [] tag = ExpireTimeCode -> DecodeExpireTime(bytes)
              [] tag = TradeNowCode -> DecodeTradeNow(bytes)
              [] tag = HandleInstCode -> DecodeHandleInst(bytes)
              [] tag = BboWeightIndicatorCode -> DecodeBboWeightIndicator(bytes)
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
        \cup { [tag |-> DiscretionPegTypeCode, body |-> one] : one \in CheckedDiscretionPegType }
        \cup { [tag |-> DiscretionPegOffsetCode, body |-> one] : one \in CheckedDiscretionPegOffset }
        \cup { [tag |-> PostOnlyCode, body |-> one] : one \in CheckedPostOnly }
        \cup { [tag |-> RandomReservesCode, body |-> one] : one \in CheckedRandomReserves }
        \cup { [tag |-> RouteCode, body |-> one] : one \in CheckedRoute }
        \cup { [tag |-> ExpireTimeCode, body |-> one] : one \in CheckedExpireTime }
        \cup { [tag |-> TradeNowCode, body |-> one] : one \in CheckedTradeNow }
        \cup { [tag |-> HandleInstCode, body |-> one] : one \in CheckedHandleInst }
        \cup { [tag |-> BboWeightIndicatorCode, body |-> one] : one \in CheckedBboWeightIndicator }

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
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> DiscretionPegTypeCode, body |-> ZeroDiscretionPegType]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> DiscretionPegOffsetCode, body |-> ZeroDiscretionPegOffset]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> PostOnlyCode, body |-> ZeroPostOnly]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> RandomReservesCode, body |-> ZeroRandomReserves]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> RouteCode, body |-> ZeroRoute]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> ExpireTimeCode, body |-> ZeroExpireTime]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> TradeNowCode, body |-> ZeroTradeNow]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> HandleInstCode, body |-> ZeroHandleInst]],
      [ZeroOrderAcceptedAppendage EXCEPT !.orderAcceptedOptionalValue = [tag |-> BboWeightIndicatorCode, body |-> ZeroBboWeightIndicator]] }

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
      [ZeroReplacedMessageAppendage EXCEPT !.replacedMessageOptionalValue = [tag |-> BboWeightIndicatorCode2, body |-> ZeroBboWeightIndicator2]] }

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
(* Canceled Message: 17 bytes                                              *)
(***************************************************************************)

CanceledMessage ==
    [ timestamp         : Sample(8),
      userRefNum        : Sample(4),
      quantity          : Sample(4),
      cancelOrderReason : Sample(1) ]

EncodeCanceledMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.quantity
        \o message.cancelOrderReason

DecodeCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(userRefNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET cancelOrderReason == ReadBytes(quantity.rest, 1) IN IF ~cancelOrderReason.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         userRefNum        |-> userRefNum.value,
         quantity          |-> quantity.value,
         cancelOrderReason |-> cancelOrderReason.value ], cancelOrderReason.rest)

ZeroCanceledMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      userRefNum        |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      cancelOrderReason |-> [i \in 1 .. 1 |-> 0] ]

(* Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedCanceledMessage ==
    { ZeroCanceledMessage }
        \cup { [ZeroCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCanceledMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCanceledMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroCanceledMessage EXCEPT !.cancelOrderReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Aiq Canceled Message: 30 bytes                                          *)
(***************************************************************************)

AiqCanceledMessage ==
    [ timestamp                    : Sample(8),
      userRefNum                   : Sample(4),
      decrementShares              : Sample(4),
      orderCancelReason            : Sample(1),
      quantityPreventedFromTrading : Sample(4),
      executionPrice               : Sample(8),
      liquidityFlag                : Sample(1) ]

EncodeAiqCanceledMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.decrementShares
        \o message.orderCancelReason
        \o message.quantityPreventedFromTrading
        \o message.executionPrice
        \o message.liquidityFlag

DecodeAiqCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET decrementShares == ReadBytes(userRefNum.rest, 4) IN IF ~decrementShares.ok THEN Fail ELSE
    LET orderCancelReason == ReadBytes(decrementShares.rest, 1) IN IF ~orderCancelReason.ok THEN Fail ELSE
    LET quantityPreventedFromTrading == ReadBytes(orderCancelReason.rest, 4) IN IF ~quantityPreventedFromTrading.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(quantityPreventedFromTrading.rest, 8) IN IF ~executionPrice.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionPrice.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         userRefNum                   |-> userRefNum.value,
         decrementShares              |-> decrementShares.value,
         orderCancelReason            |-> orderCancelReason.value,
         quantityPreventedFromTrading |-> quantityPreventedFromTrading.value,
         executionPrice               |-> executionPrice.value,
         liquidityFlag                |-> liquidityFlag.value ], liquidityFlag.rest)

ZeroAiqCanceledMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      userRefNum                   |-> [i \in 1 .. 4 |-> 0],
      decrementShares              |-> [i \in 1 .. 4 |-> 0],
      orderCancelReason            |-> [i \in 1 .. 1 |-> 0],
      quantityPreventedFromTrading |-> [i \in 1 .. 4 |-> 0],
      executionPrice               |-> [i \in 1 .. 8 |-> 0],
      liquidityFlag                |-> [i \in 1 .. 1 |-> 0] ]

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

(***************************************************************************)
(* Reference Price: 8 bytes                                                *)
(***************************************************************************)

ReferencePrice ==
    [ referencePrice : Sample(8) ]

EncodeReferencePrice(message) ==
    message.referencePrice

DecodeReferencePrice(bytes) ==
    LET referencePrice == ReadBytes(bytes, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    Ok([ referencePrice |-> referencePrice.value ], referencePrice.rest)

ZeroReferencePrice ==
    [ referencePrice |-> [i \in 1 .. 8 |-> 0] ]

(* Reference Price at zero, then each field in turn at the values it is checked at *)
CheckedReferencePrice ==
    { ZeroReferencePrice }
        \cup { [ZeroReferencePrice EXCEPT !.referencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Reference Price Type: 1 bytes                                           *)
(***************************************************************************)

ReferencePriceType ==
    [ referencePriceType : Sample(1) ]

EncodeReferencePriceType(message) ==
    message.referencePriceType

DecodeReferencePriceType(bytes) ==
    LET referencePriceType == ReadBytes(bytes, 1) IN IF ~referencePriceType.ok THEN Fail ELSE
    Ok([ referencePriceType |-> referencePriceType.value ], referencePriceType.rest)

ZeroReferencePriceType ==
    [ referencePriceType |-> [i \in 1 .. 1 |-> 0] ]

(* Reference Price Type at zero, then each field in turn at the values it is checked at *)
CheckedReferencePriceType ==
    { ZeroReferencePriceType }
        \cup { [ZeroReferencePriceType EXCEPT !.referencePriceType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Optional Value, selected by Order Executed Optional      *)
(* Field                                                                   *)
(***************************************************************************)

ReferencePriceCode == 19  \* 0x13
ReferencePriceTypeCode == 20  \* 0x14

OrderExecutedOptionalValue ==
    [ tag : {ReferencePriceCode}, body : ReferencePrice ]
        \cup [ tag : {ReferencePriceTypeCode}, body : ReferencePriceType ]

EncodeOrderExecutedOptionalValue(message) ==
    CASE message.tag = ReferencePriceCode -> EncodeReferencePrice(message.body)
      [] message.tag = ReferencePriceTypeCode -> EncodeReferencePriceType(message.body)

DecodeOrderExecutedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = ReferencePriceCode -> DecodeReferencePrice(bytes)
              [] tag = ReferencePriceTypeCode -> DecodeReferencePriceType(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderExecutedOptionalValue == [tag |-> ReferencePriceCode, body |-> ZeroReferencePrice]

(* Each Order Executed Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderExecutedOptionalValue ==
    { [tag |-> ReferencePriceCode, body |-> one] : one \in CheckedReferencePrice }
        \cup { [tag |-> ReferencePriceTypeCode, body |-> one] : one \in CheckedReferencePriceType }

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
    { [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> ReferencePriceCode, body |-> ZeroReferencePrice]],
      [ZeroOrderExecutedAppendage EXCEPT !.orderExecutedOptionalValue = [tag |-> ReferencePriceTypeCode, body |-> ZeroReferencePriceType]] }

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
(* Broken Trade Message: 35 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timestamp         : Sample(8),
      userRefNum        : Sample(4),
      matchNumber       : Sample(8),
      brokenTradeReason : Sample(1),
      clordid           : Sample(14) ]

EncodeBrokenTradeMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.matchNumber
        \o message.brokenTradeReason
        \o message.clordid

DecodeBrokenTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(userRefNum.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET brokenTradeReason == ReadBytes(matchNumber.rest, 1) IN IF ~brokenTradeReason.ok THEN Fail ELSE
    LET clordid == ReadBytes(brokenTradeReason.rest, 14) IN IF ~clordid.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         userRefNum        |-> userRefNum.value,
         matchNumber       |-> matchNumber.value,
         brokenTradeReason |-> brokenTradeReason.value,
         clordid           |-> clordid.value ], clordid.rest)

ZeroBrokenTradeMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      userRefNum        |-> [i \in 1 .. 4 |-> 0],
      matchNumber       |-> [i \in 1 .. 8 |-> 0],
      brokenTradeReason |-> [i \in 1 .. 1 |-> 0],
      clordid           |-> [i \in 1 .. 14 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.brokenTradeReason = one] : one \in Sample(1) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.clordid = one] : one \in Sample(14) }

(***************************************************************************)
(* Trade Correction Message: 48 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ timestamp             : Sample(8),
      userRefNum            : Sample(4),
      quantity              : Sample(4),
      price                 : Sample(8),
      liquidityFlag         : Sample(1),
      matchNumber           : Sample(8),
      tradeCorrectionReason : Sample(1),
      clordid               : Sample(14) ]

EncodeTradeCorrectionMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.quantity
        \o message.price
        \o message.liquidityFlag
        \o message.matchNumber
        \o message.tradeCorrectionReason
        \o message.clordid

DecodeTradeCorrectionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(userRefNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(price.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(liquidityFlag.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET tradeCorrectionReason == ReadBytes(matchNumber.rest, 1) IN IF ~tradeCorrectionReason.ok THEN Fail ELSE
    LET clordid == ReadBytes(tradeCorrectionReason.rest, 14) IN IF ~clordid.ok THEN Fail ELSE
    Ok([ timestamp             |-> timestamp.value,
         userRefNum            |-> userRefNum.value,
         quantity              |-> quantity.value,
         price                 |-> price.value,
         liquidityFlag         |-> liquidityFlag.value,
         matchNumber           |-> matchNumber.value,
         tradeCorrectionReason |-> tradeCorrectionReason.value,
         clordid               |-> clordid.value ], clordid.rest)

ZeroTradeCorrectionMessage ==
    [ timestamp             |-> [i \in 1 .. 8 |-> 0],
      userRefNum            |-> [i \in 1 .. 4 |-> 0],
      quantity              |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 8 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      matchNumber           |-> [i \in 1 .. 8 |-> 0],
      tradeCorrectionReason |-> [i \in 1 .. 1 |-> 0],
      clordid               |-> [i \in 1 .. 14 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeCorrectionReason = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.clordid = one] : one \in Sample(14) }

(***************************************************************************)
(* Rejected Order Message: 28 bytes                                        *)
(***************************************************************************)

RejectedOrderMessage ==
    [ timestamp           : Sample(8),
      userRefNum          : Sample(4),
      rejectedOrderReason : Sample(2),
      clordid             : Sample(14) ]

EncodeRejectedOrderMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.rejectedOrderReason
        \o message.clordid

DecodeRejectedOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET rejectedOrderReason == ReadBytes(userRefNum.rest, 2) IN IF ~rejectedOrderReason.ok THEN Fail ELSE
    LET clordid == ReadBytes(rejectedOrderReason.rest, 14) IN IF ~clordid.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         userRefNum          |-> userRefNum.value,
         rejectedOrderReason |-> rejectedOrderReason.value,
         clordid             |-> clordid.value ], clordid.rest)

ZeroRejectedOrderMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      userRefNum          |-> [i \in 1 .. 4 |-> 0],
      rejectedOrderReason |-> [i \in 1 .. 2 |-> 0],
      clordid             |-> [i \in 1 .. 14 |-> 0] ]

(* Rejected Order Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectedOrderMessage ==
    { ZeroRejectedOrderMessage }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.rejectedOrderReason = one] : one \in Sample(2) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.clordid = one] : one \in Sample(14) }

(***************************************************************************)
(* Cancel Pending Message: 12 bytes                                        *)
(***************************************************************************)

CancelPendingMessage ==
    [ timestamp  : Sample(8),
      userRefNum : Sample(4) ]

EncodeCancelPendingMessage(message) ==
    message.timestamp
        \o message.userRefNum

DecodeCancelPendingMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         userRefNum |-> userRefNum.value ], userRefNum.rest)

ZeroCancelPendingMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      userRefNum |-> [i \in 1 .. 4 |-> 0] ]

(* Cancel Pending Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelPendingMessage ==
    { ZeroCancelPendingMessage }
        \cup { [ZeroCancelPendingMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelPendingMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Cancel Reject Message: 12 bytes                                         *)
(***************************************************************************)

CancelRejectMessage ==
    [ timestamp  : Sample(8),
      userRefNum : Sample(4) ]

EncodeCancelRejectMessage(message) ==
    message.timestamp
        \o message.userRefNum

DecodeCancelRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         userRefNum |-> userRefNum.value ], userRefNum.rest)

ZeroCancelRejectMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      userRefNum |-> [i \in 1 .. 4 |-> 0] ]

(* Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectMessage ==
    { ZeroCancelRejectMessage }
        \cup { [ZeroCancelRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Priority Update Message: 29 bytes                                 *)
(***************************************************************************)

OrderPriorityUpdateMessage ==
    [ timestamp            : Sample(8),
      userRefNum           : Sample(4),
      price                : Sample(8),
      display              : Sample(1),
      orderReferenceNumber : Sample(8) ]

EncodeOrderPriorityUpdateMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.price
        \o message.display
        \o message.orderReferenceNumber

DecodeOrderPriorityUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET price == ReadBytes(userRefNum.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET display == ReadBytes(price.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(display.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         userRefNum           |-> userRefNum.value,
         price                |-> price.value,
         display              |-> display.value,
         orderReferenceNumber |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroOrderPriorityUpdateMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      userRefNum           |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      display              |-> [i \in 1 .. 1 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Order Priority Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderPriorityUpdateMessage ==
    { ZeroOrderPriorityUpdateMessage }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroOrderPriorityUpdateMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modified Message: 17 bytes                                        *)
(***************************************************************************)

OrderModifiedMessage ==
    [ timestamp  : Sample(8),
      userRefNum : Sample(4),
      side       : Sample(1),
      quantity   : Sample(4) ]

EncodeOrderModifiedMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.side
        \o message.quantity

DecodeOrderModifiedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET side == ReadBytes(userRefNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         userRefNum |-> userRefNum.value,
         side       |-> side.value,
         quantity   |-> quantity.value ], quantity.rest)

ZeroOrderModifiedMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      userRefNum |-> [i \in 1 .. 4 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0] ]

(* Order Modified Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifiedMessage ==
    { ZeroOrderModifiedMessage }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifiedMessage EXCEPT !.quantity = one] : one \in Sample(4) }

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
(* Order Restated Optional Value, selected by Order Restated Optional      *)
(* Field                                                                   *)
(***************************************************************************)

DisplayQuantityCode == 22  \* 0x16
DisplayPriceCode == 23  \* 0x17
SecondaryOrdRefNumCode == 1  \* 0x01

OrderRestatedOptionalValue ==
    [ tag : {DisplayQuantityCode}, body : DisplayQuantity ]
        \cup [ tag : {DisplayPriceCode}, body : DisplayPrice ]
        \cup [ tag : {SecondaryOrdRefNumCode}, body : SecondaryOrdRefNum ]

EncodeOrderRestatedOptionalValue(message) ==
    CASE message.tag = DisplayQuantityCode -> EncodeDisplayQuantity(message.body)
      [] message.tag = DisplayPriceCode -> EncodeDisplayPrice(message.body)
      [] message.tag = SecondaryOrdRefNumCode -> EncodeSecondaryOrdRefNum(message.body)

DecodeOrderRestatedOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = DisplayQuantityCode -> DecodeDisplayQuantity(bytes)
              [] tag = DisplayPriceCode -> DecodeDisplayPrice(bytes)
              [] tag = SecondaryOrdRefNumCode -> DecodeSecondaryOrdRefNum(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroOrderRestatedOptionalValue == [tag |-> DisplayQuantityCode, body |-> ZeroDisplayQuantity]

(* Each Order Restated Optional Value in turn, at the values the message it names is checked at *)
CheckedOrderRestatedOptionalValue ==
    { [tag |-> DisplayQuantityCode, body |-> one] : one \in CheckedDisplayQuantity }
        \cup { [tag |-> DisplayPriceCode, body |-> one] : one \in CheckedDisplayPrice }
        \cup { [tag |-> SecondaryOrdRefNumCode, body |-> one] : one \in CheckedSecondaryOrdRefNum }

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
      [ZeroOrderRestatedAppendage EXCEPT !.orderRestatedOptionalValue = [tag |-> SecondaryOrdRefNumCode, body |-> ZeroSecondaryOrdRefNum]] }

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
(* Account Query Response Message: 12 bytes                                *)
(***************************************************************************)

AccountQueryResponseMessage ==
    [ timestamp      : Sample(8),
      nextUserRefNum : Sample(4) ]

EncodeAccountQueryResponseMessage(message) ==
    message.timestamp
        \o message.nextUserRefNum

DecodeAccountQueryResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET nextUserRefNum == ReadBytes(timestamp.rest, 4) IN IF ~nextUserRefNum.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         nextUserRefNum |-> nextUserRefNum.value ], nextUserRefNum.rest)

ZeroAccountQueryResponseMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      nextUserRefNum |-> [i \in 1 .. 4 |-> 0] ]

(* Account Query Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryResponseMessage ==
    { ZeroAccountQueryResponseMessage }
        \cup { [ZeroAccountQueryResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAccountQueryResponseMessage EXCEPT !.nextUserRefNum = one] : one \in Sample(4) }

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
(* Mass Cancel Response Optional Value, selected by Mass Cancel Response   *)
(* Optional Field                                                          *)
(***************************************************************************)

SideCode == 27  \* 0x1b
GroupIdCode == 24  \* 0x18
UserRefIdxCode == 28  \* 0x1c

MassCancelResponseOptionalValue ==
    [ tag : {SideCode}, body : Side ]
        \cup [ tag : {GroupIdCode}, body : GroupId ]
        \cup [ tag : {UserRefIdxCode}, body : UserRefIdx ]

EncodeMassCancelResponseOptionalValue(message) ==
    CASE message.tag = SideCode -> EncodeSide(message.body)
      [] message.tag = GroupIdCode -> EncodeGroupId(message.body)
      [] message.tag = UserRefIdxCode -> EncodeUserRefIdx(message.body)

DecodeMassCancelResponseOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = SideCode -> DecodeSide(bytes)
              [] tag = GroupIdCode -> DecodeGroupId(bytes)
              [] tag = UserRefIdxCode -> DecodeUserRefIdx(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMassCancelResponseOptionalValue == [tag |-> SideCode, body |-> ZeroSide]

(* Each Mass Cancel Response Optional Value in turn, at the values the message it names is checked at *)
CheckedMassCancelResponseOptionalValue ==
    { [tag |-> SideCode, body |-> one] : one \in CheckedSide }
        \cup { [tag |-> GroupIdCode, body |-> one] : one \in CheckedGroupId }
        \cup { [tag |-> UserRefIdxCode, body |-> one] : one \in CheckedUserRefIdx }

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
      [ZeroMassCancelResponseAppendage EXCEPT !.massCancelResponseOptionalValue = [tag |-> GroupIdCode, body |-> ZeroGroupId]],
      [ZeroMassCancelResponseAppendage EXCEPT !.massCancelResponseOptionalValue = [tag |-> UserRefIdxCode, body |-> ZeroUserRefIdx]] }

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
(* Disable Order Entry Response Optional Value, selected by Disable Order  *)
(* Entry Response Optional Field                                           *)
(***************************************************************************)

UserRefIdxCode2 == 28  \* 0x1c

DisableOrderEntryResponseOptionalValue ==
    [ tag : {UserRefIdxCode2}, body : UserRefIdx2 ]

EncodeDisableOrderEntryResponseOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode2 -> EncodeUserRefIdx2(message.body)

DecodeDisableOrderEntryResponseOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode2 -> DecodeUserRefIdx2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroDisableOrderEntryResponseOptionalValue == [tag |-> UserRefIdxCode2, body |-> ZeroUserRefIdx2]

(* Each Disable Order Entry Response Optional Value in turn, at the values the message it names is checked at *)
CheckedDisableOrderEntryResponseOptionalValue ==
    { [tag |-> UserRefIdxCode2, body |-> one] : one \in CheckedUserRefIdx2 }

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
    { [ZeroDisableOrderEntryResponseAppendage EXCEPT !.disableOrderEntryResponseOptionalValue = [tag |-> UserRefIdxCode2, body |-> ZeroUserRefIdx2]] }

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
(* Enable Order Entry Response Optional Value, selected by Enable Order    *)
(* Entry Response Optional Field                                           *)
(***************************************************************************)

UserRefIdxCode3 == 28  \* 0x1c

EnableOrderEntryResponseOptionalValue ==
    [ tag : {UserRefIdxCode3}, body : UserRefIdx3 ]

EncodeEnableOrderEntryResponseOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode3 -> EncodeUserRefIdx3(message.body)

DecodeEnableOrderEntryResponseOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode3 -> DecodeUserRefIdx3(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroEnableOrderEntryResponseOptionalValue == [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]

(* Each Enable Order Entry Response Optional Value in turn, at the values the message it names is checked at *)
CheckedEnableOrderEntryResponseOptionalValue ==
    { [tag |-> UserRefIdxCode3, body |-> one] : one \in CheckedUserRefIdx3 }

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
    { [ZeroEnableOrderEntryResponseAppendage EXCEPT !.enableOrderEntryResponseOptionalValue = [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]] }

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
TradeCorrectionMessageCode == 70  \* "F"
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
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
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
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
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
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
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
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
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

(* Every Discretion Peg Type decodes back to what was encoded, and leaves nothing over *)
RoundTripDiscretionPegType ==
    \A message \in CheckedDiscretionPegType :
        LET read == DecodeDiscretionPegType(EncodeDiscretionPegType(message))
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

(* Every Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCanceledMessage ==
    \A message \in CheckedCanceledMessage :
        LET read == DecodeCanceledMessage(EncodeCanceledMessage(message))
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

(* Every Reference Price decodes back to what was encoded, and leaves nothing over *)
RoundTripReferencePrice ==
    \A message \in CheckedReferencePrice :
        LET read == DecodeReferencePrice(EncodeReferencePrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reference Price Type decodes back to what was encoded, and leaves nothing over *)
RoundTripReferencePriceType ==
    \A message \in CheckedReferencePriceType :
        LET read == DecodeReferencePriceType(EncodeReferencePriceType(message))
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

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
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

(* Every Cancel Pending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelPendingMessage ==
    \A message \in CheckedCancelPendingMessage :
        LET read == DecodeCancelPendingMessage(EncodeCancelPendingMessage(message))
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

(* Every Order Priority Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderPriorityUpdateMessage ==
    \A message \in CheckedOrderPriorityUpdateMessage :
        LET read == DecodeOrderPriorityUpdateMessage(EncodeOrderPriorityUpdateMessage(message))
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
RoundTripGroupId ==
    \A message \in CheckedGroupId :
        LET read == DecodeGroupId(EncodeGroupId(message))
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
RoundTripUserRefIdx2 ==
    \A message \in CheckedUserRefIdx2 :
        LET read == DecodeUserRefIdx2(EncodeUserRefIdx2(message))
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
RoundTripUserRefIdx3 ==
    \A message \in CheckedUserRefIdx3 :
        LET read == DecodeUserRefIdx3(EncodeUserRefIdx3(message))
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

(* A Order Executed Optional Value is selected by the Order Executed Optional Field it is written under *)
SelectsOrderExecutedOptionalValue ==
    \A message \in CheckedOrderExecutedOptionalValue :
        LET read == DecodeOrderExecutedOptionalValue(message.tag, EncodeOrderExecutedOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Order Restated Optional Value is selected by the Order Restated Optional Field it is written under *)
SelectsOrderRestatedOptionalValue ==
    \A message \in CheckedOrderRestatedOptionalValue :
        LET read == DecodeOrderRestatedOptionalValue(message.tag, EncodeOrderRestatedOptionalValue(message))
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
FramesOrderExecutedAppendage ==
    \A message \in CheckedOrderExecutedAppendage :
        LET bytes == EncodeOrderExecutedAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesOrderRestatedAppendage ==
    \A message \in CheckedOrderRestatedAppendage :
        LET bytes == EncodeOrderRestatedAppendage(message)
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
