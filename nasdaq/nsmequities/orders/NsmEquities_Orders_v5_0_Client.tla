------------------ MODULE NsmEquities_Orders_v5_0_Client -------------------
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
(* Enter Order Optional Value, selected by Enter Order Optional Field      *)
(***************************************************************************)

FirmCode == 2  \* 0x02
MinQtyCode == 3  \* 0x03
CustomerTypeCode == 4  \* 0x04
MaxFloorCode == 5  \* 0x05

EnterOrderOptionalValue ==
    [ tag : {FirmCode}, body : Firm ]
        \cup [ tag : {MinQtyCode}, body : MinQty ]
        \cup [ tag : {CustomerTypeCode}, body : CustomerType ]
        \cup [ tag : {MaxFloorCode}, body : MaxFloor ]

EncodeEnterOrderOptionalValue(message) ==
    CASE message.tag = FirmCode -> EncodeFirm(message.body)
      [] message.tag = MinQtyCode -> EncodeMinQty(message.body)
      [] message.tag = CustomerTypeCode -> EncodeCustomerType(message.body)
      [] message.tag = MaxFloorCode -> EncodeMaxFloor(message.body)

DecodeEnterOrderOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = FirmCode -> DecodeFirm(bytes)
              [] tag = MinQtyCode -> DecodeMinQty(bytes)
              [] tag = CustomerTypeCode -> DecodeCustomerType(bytes)
              [] tag = MaxFloorCode -> DecodeMaxFloor(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroEnterOrderOptionalValue == [tag |-> FirmCode, body |-> ZeroFirm]

(* Each Enter Order Optional Value in turn, at the values the message it names is checked at *)
CheckedEnterOrderOptionalValue ==
    { [tag |-> FirmCode, body |-> one] : one \in CheckedFirm }
        \cup { [tag |-> MinQtyCode, body |-> one] : one \in CheckedMinQty }
        \cup { [tag |-> CustomerTypeCode, body |-> one] : one \in CheckedCustomerType }
        \cup { [tag |-> MaxFloorCode, body |-> one] : one \in CheckedMaxFloor }

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
    { [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> FirmCode, body |-> ZeroFirm]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> MinQtyCode, body |-> ZeroMinQty]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> CustomerTypeCode, body |-> ZeroCustomerType]],
      [ZeroEnterOrderAppendage EXCEPT !.enterOrderOptionalValue = [tag |-> MaxFloorCode, body |-> ZeroMaxFloor]] }

(***************************************************************************)
(* Enter Order Message                                                     *)
(***************************************************************************)

EnterOrderMessage ==
    [ userRefNum                  : Sample(4),
      side                        : Sample(1),
      quantity                    : Sample(4),
      symbol                      : Sample(8),
      price                       : Sample(8),
      timeInForce                 : Sample(1),
      display                     : Sample(1),
      capacity                    : Sample(1),
      interMarketSweepEligibility : Sample(1),
      crossType                   : Sample(1),
      clordid                     : Sample(14),
      enterOrderAppendage         : SampleLists(OneEnterOrderAppendage) ]

EncodeEnterOrderMessage(message) ==
    LET payload == EncodeEnterOrderAppendageList(message.enterOrderAppendage)
    IN  message.userRefNum
            \o message.side
            \o message.quantity
            \o message.symbol
            \o message.price
            \o message.timeInForce
            \o message.display
            \o message.capacity
            \o message.interMarketSweepEligibility
            \o message.crossType
            \o message.clordid
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeEnterOrderMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET side == ReadBytes(userRefNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET symbol == ReadBytes(quantity.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET price == ReadBytes(symbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET display == ReadBytes(timeInForce.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET capacity == ReadBytes(display.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET interMarketSweepEligibility == ReadBytes(capacity.rest, 1) IN IF ~interMarketSweepEligibility.ok THEN Fail ELSE
    LET crossType == ReadBytes(interMarketSweepEligibility.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET clordid == ReadBytes(crossType.rest, 14) IN IF ~clordid.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(clordid.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        enterOrderAppendage == ReadEnterOrderAppendageAll(framed)
    IN  IF ~enterOrderAppendage.ok \/ enterOrderAppendage.rest # << >> THEN Fail ELSE
    Ok([ userRefNum                  |-> userRefNum.value,
         side                        |-> side.value,
         quantity                    |-> quantity.value,
         symbol                      |-> symbol.value,
         price                       |-> price.value,
         timeInForce                 |-> timeInForce.value,
         display                     |-> display.value,
         capacity                    |-> capacity.value,
         interMarketSweepEligibility |-> interMarketSweepEligibility.value,
         crossType                   |-> crossType.value,
         clordid                     |-> clordid.value,
         enterOrderAppendage         |-> enterOrderAppendage.value ], beyond)

ZeroEnterOrderMessage ==
    [ userRefNum                  |-> [i \in 1 .. 4 |-> 0],
      side                        |-> [i \in 1 .. 1 |-> 0],
      quantity                    |-> [i \in 1 .. 4 |-> 0],
      symbol                      |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      display                     |-> [i \in 1 .. 1 |-> 0],
      capacity                    |-> [i \in 1 .. 1 |-> 0],
      interMarketSweepEligibility |-> [i \in 1 .. 1 |-> 0],
      crossType                   |-> [i \in 1 .. 1 |-> 0],
      clordid                     |-> [i \in 1 .. 14 |-> 0],
      enterOrderAppendage         |-> << >> ]

(* Enter Order Message at zero, then each field in turn at the values it is checked at *)
CheckedEnterOrderMessage ==
    { ZeroEnterOrderMessage }
        \cup { [ZeroEnterOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.interMarketSweepEligibility = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.clordid = one] : one \in Sample(14) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.enterOrderAppendage = one] : one \in SampleLists(OneEnterOrderAppendage) }

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
(* Replace Order Optional Value, selected by Replace Order Optional Field  *)
(***************************************************************************)

MinQtyCode2 == 3  \* 0x03
MaxFloorCode2 == 5  \* 0x05
PriceTypeCode == 6  \* 0x06
PostOnlyCode == 12  \* 0x0c
ExpireTimeCode == 15  \* 0x0f
TradeNowCode == 16  \* 0x10
HandleInstCode == 17  \* 0x11

ReplaceOrderOptionalValue ==
    [ tag : {MinQtyCode2}, body : MinQty2 ]
        \cup [ tag : {MaxFloorCode2}, body : MaxFloor2 ]
        \cup [ tag : {PriceTypeCode}, body : PriceType ]
        \cup [ tag : {PostOnlyCode}, body : PostOnly ]
        \cup [ tag : {ExpireTimeCode}, body : ExpireTime ]
        \cup [ tag : {TradeNowCode}, body : TradeNow ]
        \cup [ tag : {HandleInstCode}, body : HandleInst ]

EncodeReplaceOrderOptionalValue(message) ==
    CASE message.tag = MinQtyCode2 -> EncodeMinQty2(message.body)
      [] message.tag = MaxFloorCode2 -> EncodeMaxFloor2(message.body)
      [] message.tag = PriceTypeCode -> EncodePriceType(message.body)
      [] message.tag = PostOnlyCode -> EncodePostOnly(message.body)
      [] message.tag = ExpireTimeCode -> EncodeExpireTime(message.body)
      [] message.tag = TradeNowCode -> EncodeTradeNow(message.body)
      [] message.tag = HandleInstCode -> EncodeHandleInst(message.body)

DecodeReplaceOrderOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = MinQtyCode2 -> DecodeMinQty2(bytes)
              [] tag = MaxFloorCode2 -> DecodeMaxFloor2(bytes)
              [] tag = PriceTypeCode -> DecodePriceType(bytes)
              [] tag = PostOnlyCode -> DecodePostOnly(bytes)
              [] tag = ExpireTimeCode -> DecodeExpireTime(bytes)
              [] tag = TradeNowCode -> DecodeTradeNow(bytes)
              [] tag = HandleInstCode -> DecodeHandleInst(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroReplaceOrderOptionalValue == [tag |-> MinQtyCode2, body |-> ZeroMinQty2]

(* Each Replace Order Optional Value in turn, at the values the message it names is checked at *)
CheckedReplaceOrderOptionalValue ==
    { [tag |-> MinQtyCode2, body |-> one] : one \in CheckedMinQty2 }
        \cup { [tag |-> MaxFloorCode2, body |-> one] : one \in CheckedMaxFloor2 }
        \cup { [tag |-> PriceTypeCode, body |-> one] : one \in CheckedPriceType }
        \cup { [tag |-> PostOnlyCode, body |-> one] : one \in CheckedPostOnly }
        \cup { [tag |-> ExpireTimeCode, body |-> one] : one \in CheckedExpireTime }
        \cup { [tag |-> TradeNowCode, body |-> one] : one \in CheckedTradeNow }
        \cup { [tag |-> HandleInstCode, body |-> one] : one \in CheckedHandleInst }

(***************************************************************************)
(* Replace Order Appendage, framed by Optional Field Length                *)
(***************************************************************************)

ReplaceOrderAppendage ==
    [ replaceOrderOptionalValue : ReplaceOrderOptionalValue ]

EncodeReplaceOrderAppendageBody(message) ==
    EncodeUIntBE(message.replaceOrderOptionalValue.tag, 1)
        \o EncodeReplaceOrderOptionalValue(message.replaceOrderOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeReplaceOrderAppendage(message) ==
    LET body == EncodeReplaceOrderAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeReplaceOrderAppendageBody(bytes) ==
    LET replaceOrderOptionalField == ReadUIntBE(bytes, 1) IN IF ~replaceOrderOptionalField.ok THEN Fail ELSE
    LET replaceOrderOptionalValue == DecodeReplaceOrderOptionalValue(replaceOrderOptionalField.value, replaceOrderOptionalField.rest) IN IF ~replaceOrderOptionalValue.ok THEN Fail ELSE
    Ok([ replaceOrderOptionalValue |-> replaceOrderOptionalValue.value ], replaceOrderOptionalValue.rest)

DecodeReplaceOrderAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeReplaceOrderAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroReplaceOrderAppendage ==
    [ replaceOrderOptionalValue |-> ZeroReplaceOrderOptionalValue ]

(* Replace Order Appendage at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderAppendage ==
    { ZeroReplaceOrderAppendage }
        \cup { [ZeroReplaceOrderAppendage EXCEPT !.replaceOrderOptionalValue = one] : one \in CheckedReplaceOrderOptionalValue }

(* A run of Replace Order Appendage, written one after another *)
RECURSIVE EncodeReplaceOrderAppendageList(_)
EncodeReplaceOrderAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeReplaceOrderAppendage(Head(messages)) \o EncodeReplaceOrderAppendageList(Tail(messages))

(* As many Replace Order Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadReplaceOrderAppendageAll(_)
ReadReplaceOrderAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeReplaceOrderAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadReplaceOrderAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Replace Order Appendage of each kind, for the lists that carry them *)
OneReplaceOrderAppendage ==
    { [ZeroReplaceOrderAppendage EXCEPT !.replaceOrderOptionalValue = [tag |-> MinQtyCode2, body |-> ZeroMinQty2]],
      [ZeroReplaceOrderAppendage EXCEPT !.replaceOrderOptionalValue = [tag |-> MaxFloorCode2, body |-> ZeroMaxFloor2]],
      [ZeroReplaceOrderAppendage EXCEPT !.replaceOrderOptionalValue = [tag |-> PriceTypeCode, body |-> ZeroPriceType]],
      [ZeroReplaceOrderAppendage EXCEPT !.replaceOrderOptionalValue = [tag |-> PostOnlyCode, body |-> ZeroPostOnly]],
      [ZeroReplaceOrderAppendage EXCEPT !.replaceOrderOptionalValue = [tag |-> ExpireTimeCode, body |-> ZeroExpireTime]],
      [ZeroReplaceOrderAppendage EXCEPT !.replaceOrderOptionalValue = [tag |-> TradeNowCode, body |-> ZeroTradeNow]],
      [ZeroReplaceOrderAppendage EXCEPT !.replaceOrderOptionalValue = [tag |-> HandleInstCode, body |-> ZeroHandleInst]] }

(***************************************************************************)
(* Replace Order Message                                                   *)
(***************************************************************************)

ReplaceOrderMessage ==
    [ origUserRefNum              : Sample(4),
      userRefNum                  : Sample(4),
      quantity                    : Sample(4),
      price                       : Sample(8),
      timeInForce                 : Sample(1),
      display                     : Sample(1),
      interMarketSweepEligibility : Sample(1),
      clordid                     : Sample(14),
      replaceOrderAppendage       : SampleLists(OneReplaceOrderAppendage) ]

EncodeReplaceOrderMessage(message) ==
    LET payload == EncodeReplaceOrderAppendageList(message.replaceOrderAppendage)
    IN  message.origUserRefNum
            \o message.userRefNum
            \o message.quantity
            \o message.price
            \o message.timeInForce
            \o message.display
            \o message.interMarketSweepEligibility
            \o message.clordid
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeReplaceOrderMessage(bytes) ==
    LET origUserRefNum == ReadBytes(bytes, 4) IN IF ~origUserRefNum.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(origUserRefNum.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(userRefNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(price.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET display == ReadBytes(timeInForce.rest, 1) IN IF ~display.ok THEN Fail ELSE
    LET interMarketSweepEligibility == ReadBytes(display.rest, 1) IN IF ~interMarketSweepEligibility.ok THEN Fail ELSE
    LET clordid == ReadBytes(interMarketSweepEligibility.rest, 14) IN IF ~clordid.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(clordid.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        replaceOrderAppendage == ReadReplaceOrderAppendageAll(framed)
    IN  IF ~replaceOrderAppendage.ok \/ replaceOrderAppendage.rest # << >> THEN Fail ELSE
    Ok([ origUserRefNum              |-> origUserRefNum.value,
         userRefNum                  |-> userRefNum.value,
         quantity                    |-> quantity.value,
         price                       |-> price.value,
         timeInForce                 |-> timeInForce.value,
         display                     |-> display.value,
         interMarketSweepEligibility |-> interMarketSweepEligibility.value,
         clordid                     |-> clordid.value,
         replaceOrderAppendage       |-> replaceOrderAppendage.value ], beyond)

ZeroReplaceOrderMessage ==
    [ origUserRefNum              |-> [i \in 1 .. 4 |-> 0],
      userRefNum                  |-> [i \in 1 .. 4 |-> 0],
      quantity                    |-> [i \in 1 .. 4 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      timeInForce                 |-> [i \in 1 .. 1 |-> 0],
      display                     |-> [i \in 1 .. 1 |-> 0],
      interMarketSweepEligibility |-> [i \in 1 .. 1 |-> 0],
      clordid                     |-> [i \in 1 .. 14 |-> 0],
      replaceOrderAppendage       |-> << >> ]

(* Replace Order Message at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderMessage ==
    { ZeroReplaceOrderMessage }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.origUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.display = one] : one \in Sample(1) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.interMarketSweepEligibility = one] : one \in Sample(1) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.clordid = one] : one \in Sample(14) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.replaceOrderAppendage = one] : one \in SampleLists(OneReplaceOrderAppendage) }

(***************************************************************************)
(* Cancel Order Message: 8 bytes                                           *)
(***************************************************************************)

CancelOrderMessage ==
    [ userRefNum : Sample(4),
      quantity   : Sample(4) ]

EncodeCancelOrderMessage(message) ==
    message.userRefNum
        \o message.quantity

DecodeCancelOrderMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(userRefNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ userRefNum |-> userRefNum.value,
         quantity   |-> quantity.value ], quantity.rest)

ZeroCancelOrderMessage ==
    [ userRefNum |-> [i \in 1 .. 4 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Order Message: 9 bytes                                           *)
(***************************************************************************)

ModifyOrderMessage ==
    [ userRefNum : Sample(4),
      side       : Sample(1),
      quantity   : Sample(4) ]

EncodeModifyOrderMessage(message) ==
    message.userRefNum
        \o message.side
        \o message.quantity

DecodeModifyOrderMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET side == ReadBytes(userRefNum.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ userRefNum |-> userRefNum.value,
         side       |-> side.value,
         quantity   |-> quantity.value ], quantity.rest)

ZeroModifyOrderMessage ==
    [ userRefNum |-> [i \in 1 .. 4 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }

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
(* Account Query Optional Value, selected by Account Query Optional Field  *)
(***************************************************************************)

UserRefIdxCode == 28  \* 0x1c

AccountQueryOptionalValue ==
    [ tag : {UserRefIdxCode}, body : UserRefIdx ]

EncodeAccountQueryOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode -> EncodeUserRefIdx(message.body)

DecodeAccountQueryOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode -> DecodeUserRefIdx(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroAccountQueryOptionalValue == [tag |-> UserRefIdxCode, body |-> ZeroUserRefIdx]

(* Each Account Query Optional Value in turn, at the values the message it names is checked at *)
CheckedAccountQueryOptionalValue ==
    { [tag |-> UserRefIdxCode, body |-> one] : one \in CheckedUserRefIdx }

(***************************************************************************)
(* Account Query Appendage, framed by Optional Field Length                *)
(***************************************************************************)

AccountQueryAppendage ==
    [ accountQueryOptionalValue : AccountQueryOptionalValue ]

EncodeAccountQueryAppendageBody(message) ==
    EncodeUIntBE(message.accountQueryOptionalValue.tag, 1)
        \o EncodeAccountQueryOptionalValue(message.accountQueryOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeAccountQueryAppendage(message) ==
    LET body == EncodeAccountQueryAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeAccountQueryAppendageBody(bytes) ==
    LET accountQueryOptionalField == ReadUIntBE(bytes, 1) IN IF ~accountQueryOptionalField.ok THEN Fail ELSE
    LET accountQueryOptionalValue == DecodeAccountQueryOptionalValue(accountQueryOptionalField.value, accountQueryOptionalField.rest) IN IF ~accountQueryOptionalValue.ok THEN Fail ELSE
    Ok([ accountQueryOptionalValue |-> accountQueryOptionalValue.value ], accountQueryOptionalValue.rest)

DecodeAccountQueryAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeAccountQueryAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroAccountQueryAppendage ==
    [ accountQueryOptionalValue |-> ZeroAccountQueryOptionalValue ]

(* Account Query Appendage at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryAppendage ==
    { ZeroAccountQueryAppendage }
        \cup { [ZeroAccountQueryAppendage EXCEPT !.accountQueryOptionalValue = one] : one \in CheckedAccountQueryOptionalValue }

(* A run of Account Query Appendage, written one after another *)
RECURSIVE EncodeAccountQueryAppendageList(_)
EncodeAccountQueryAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAccountQueryAppendage(Head(messages)) \o EncodeAccountQueryAppendageList(Tail(messages))

(* As many Account Query Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadAccountQueryAppendageAll(_)
ReadAccountQueryAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeAccountQueryAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAccountQueryAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Account Query Appendage of each kind, for the lists that carry them *)
OneAccountQueryAppendage ==
    { [ZeroAccountQueryAppendage EXCEPT !.accountQueryOptionalValue = [tag |-> UserRefIdxCode, body |-> ZeroUserRefIdx]] }

(***************************************************************************)
(* Account Query Message                                                   *)
(***************************************************************************)

AccountQueryMessageTail ==
    [ accountQueryAppendage : SampleLists(OneAccountQueryAppendage) ]

EncodeAccountQueryMessageTail(message) ==
    LET payload == EncodeAccountQueryAppendageList(message.accountQueryAppendage)
    IN  EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeAccountQueryMessageTail(bytes) ==
    LET appendageLength == ReadUIntBE(bytes, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        accountQueryAppendage == ReadAccountQueryAppendageAll(framed)
    IN  IF ~accountQueryAppendage.ok \/ accountQueryAppendage.rest # << >> THEN Fail ELSE
    Ok([ accountQueryAppendage |-> accountQueryAppendage.value ], beyond)

ZeroAccountQueryMessageTail ==
    [ accountQueryAppendage |-> << >> ]

(* Account Query Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryMessageTail ==
    { ZeroAccountQueryMessageTail }
        \cup { [ZeroAccountQueryMessageTail EXCEPT !.accountQueryAppendage = one] : one \in SampleLists(OneAccountQueryAppendage) }

(* Account Query Message runs on only when bytes remain, so it is there or it is not *)
WithoutAccountQueryMessageTail == [there |-> FALSE, value |-> ZeroAccountQueryMessageTail]

MaybeAccountQueryMessageTail ==
    { WithoutAccountQueryMessageTail }
        \cup { [there |-> TRUE, value |-> one] : one \in CheckedAccountQueryMessageTail }

ReadAccountQueryMessageTailMaybe(bytes) ==
    IF bytes = << >> THEN Ok(WithoutAccountQueryMessageTail, << >>)
    ELSE LET one == DecodeAccountQueryMessageTail(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE Ok([there |-> TRUE, value |-> one.value], one.rest)

(***************************************************************************)
(* Account Query Message                                                   *)
(***************************************************************************)

AccountQueryMessage ==
    [ accountQueryMessageTail : MaybeAccountQueryMessageTail ]

EncodeAccountQueryMessage(message) ==
    IF message.accountQueryMessageTail.there THEN EncodeAccountQueryMessageTail(message.accountQueryMessageTail.value) ELSE << >>

DecodeAccountQueryMessage(bytes) ==
    LET accountQueryMessageTail == ReadAccountQueryMessageTailMaybe(bytes) IN IF ~accountQueryMessageTail.ok THEN Fail ELSE
    Ok([ accountQueryMessageTail |-> accountQueryMessageTail.value ], accountQueryMessageTail.rest)

ZeroAccountQueryMessage ==
    [ accountQueryMessageTail |-> WithoutAccountQueryMessageTail ]

(* Account Query Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryMessage ==
    { ZeroAccountQueryMessage }
        \cup { [ZeroAccountQueryMessage EXCEPT !.accountQueryMessageTail = one] : one \in MaybeAccountQueryMessageTail }

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
(* Mass Cancel Request Optional Value, selected by Mass Cancel Request     *)
(* Optional Field                                                          *)
(***************************************************************************)

SideCode == 27  \* 0x1b
GroupIdCode == 24  \* 0x18
UserRefIdxCode2 == 28  \* 0x1c

MassCancelRequestOptionalValue ==
    [ tag : {SideCode}, body : Side ]
        \cup [ tag : {GroupIdCode}, body : GroupId ]
        \cup [ tag : {UserRefIdxCode2}, body : UserRefIdx2 ]

EncodeMassCancelRequestOptionalValue(message) ==
    CASE message.tag = SideCode -> EncodeSide(message.body)
      [] message.tag = GroupIdCode -> EncodeGroupId(message.body)
      [] message.tag = UserRefIdxCode2 -> EncodeUserRefIdx2(message.body)

DecodeMassCancelRequestOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = SideCode -> DecodeSide(bytes)
              [] tag = GroupIdCode -> DecodeGroupId(bytes)
              [] tag = UserRefIdxCode2 -> DecodeUserRefIdx2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMassCancelRequestOptionalValue == [tag |-> SideCode, body |-> ZeroSide]

(* Each Mass Cancel Request Optional Value in turn, at the values the message it names is checked at *)
CheckedMassCancelRequestOptionalValue ==
    { [tag |-> SideCode, body |-> one] : one \in CheckedSide }
        \cup { [tag |-> GroupIdCode, body |-> one] : one \in CheckedGroupId }
        \cup { [tag |-> UserRefIdxCode2, body |-> one] : one \in CheckedUserRefIdx2 }

(***************************************************************************)
(* Mass Cancel Request Appendage, framed by Optional Field Length          *)
(***************************************************************************)

MassCancelRequestAppendage ==
    [ massCancelRequestOptionalValue : MassCancelRequestOptionalValue ]

EncodeMassCancelRequestAppendageBody(message) ==
    EncodeUIntBE(message.massCancelRequestOptionalValue.tag, 1)
        \o EncodeMassCancelRequestOptionalValue(message.massCancelRequestOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeMassCancelRequestAppendage(message) ==
    LET body == EncodeMassCancelRequestAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeMassCancelRequestAppendageBody(bytes) ==
    LET massCancelRequestOptionalField == ReadUIntBE(bytes, 1) IN IF ~massCancelRequestOptionalField.ok THEN Fail ELSE
    LET massCancelRequestOptionalValue == DecodeMassCancelRequestOptionalValue(massCancelRequestOptionalField.value, massCancelRequestOptionalField.rest) IN IF ~massCancelRequestOptionalValue.ok THEN Fail ELSE
    Ok([ massCancelRequestOptionalValue |-> massCancelRequestOptionalValue.value ], massCancelRequestOptionalValue.rest)

DecodeMassCancelRequestAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMassCancelRequestAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMassCancelRequestAppendage ==
    [ massCancelRequestOptionalValue |-> ZeroMassCancelRequestOptionalValue ]

(* Mass Cancel Request Appendage at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRequestAppendage ==
    { ZeroMassCancelRequestAppendage }
        \cup { [ZeroMassCancelRequestAppendage EXCEPT !.massCancelRequestOptionalValue = one] : one \in CheckedMassCancelRequestOptionalValue }

(* A run of Mass Cancel Request Appendage, written one after another *)
RECURSIVE EncodeMassCancelRequestAppendageList(_)
EncodeMassCancelRequestAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMassCancelRequestAppendage(Head(messages)) \o EncodeMassCancelRequestAppendageList(Tail(messages))

(* As many Mass Cancel Request Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMassCancelRequestAppendageAll(_)
ReadMassCancelRequestAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMassCancelRequestAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMassCancelRequestAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mass Cancel Request Appendage of each kind, for the lists that carry them *)
OneMassCancelRequestAppendage ==
    { [ZeroMassCancelRequestAppendage EXCEPT !.massCancelRequestOptionalValue = [tag |-> SideCode, body |-> ZeroSide]],
      [ZeroMassCancelRequestAppendage EXCEPT !.massCancelRequestOptionalValue = [tag |-> GroupIdCode, body |-> ZeroGroupId]],
      [ZeroMassCancelRequestAppendage EXCEPT !.massCancelRequestOptionalValue = [tag |-> UserRefIdxCode2, body |-> ZeroUserRefIdx2]] }

(***************************************************************************)
(* Mass Cancel Request Message                                             *)
(***************************************************************************)

MassCancelRequestMessage ==
    [ userRefNum                 : Sample(4),
      firm                       : Sample(4),
      symbol                     : Sample(8),
      massCancelRequestAppendage : SampleLists(OneMassCancelRequestAppendage) ]

EncodeMassCancelRequestMessage(message) ==
    LET payload == EncodeMassCancelRequestAppendageList(message.massCancelRequestAppendage)
    IN  message.userRefNum
            \o message.firm
            \o message.symbol
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeMassCancelRequestMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET firm == ReadBytes(userRefNum.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET symbol == ReadBytes(firm.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(symbol.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        massCancelRequestAppendage == ReadMassCancelRequestAppendageAll(framed)
    IN  IF ~massCancelRequestAppendage.ok \/ massCancelRequestAppendage.rest # << >> THEN Fail ELSE
    Ok([ userRefNum                 |-> userRefNum.value,
         firm                       |-> firm.value,
         symbol                     |-> symbol.value,
         massCancelRequestAppendage |-> massCancelRequestAppendage.value ], beyond)

ZeroMassCancelRequestMessage ==
    [ userRefNum                 |-> [i \in 1 .. 4 |-> 0],
      firm                       |-> [i \in 1 .. 4 |-> 0],
      symbol                     |-> [i \in 1 .. 8 |-> 0],
      massCancelRequestAppendage |-> << >> ]

(* Mass Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelRequestMessage ==
    { ZeroMassCancelRequestMessage }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelRequestMessage EXCEPT !.massCancelRequestAppendage = one] : one \in SampleLists(OneMassCancelRequestAppendage) }

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
(* Disable Order Entry Request Optional Value, selected by Disable Order   *)
(* Entry Request Optional Field                                            *)
(***************************************************************************)

UserRefIdxCode3 == 28  \* 0x1c

DisableOrderEntryRequestOptionalValue ==
    [ tag : {UserRefIdxCode3}, body : UserRefIdx3 ]

EncodeDisableOrderEntryRequestOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode3 -> EncodeUserRefIdx3(message.body)

DecodeDisableOrderEntryRequestOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode3 -> DecodeUserRefIdx3(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroDisableOrderEntryRequestOptionalValue == [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]

(* Each Disable Order Entry Request Optional Value in turn, at the values the message it names is checked at *)
CheckedDisableOrderEntryRequestOptionalValue ==
    { [tag |-> UserRefIdxCode3, body |-> one] : one \in CheckedUserRefIdx3 }

(***************************************************************************)
(* Disable Order Entry Request Appendage, framed by Optional Field Length  *)
(***************************************************************************)

DisableOrderEntryRequestAppendage ==
    [ disableOrderEntryRequestOptionalValue : DisableOrderEntryRequestOptionalValue ]

EncodeDisableOrderEntryRequestAppendageBody(message) ==
    EncodeUIntBE(message.disableOrderEntryRequestOptionalValue.tag, 1)
        \o EncodeDisableOrderEntryRequestOptionalValue(message.disableOrderEntryRequestOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeDisableOrderEntryRequestAppendage(message) ==
    LET body == EncodeDisableOrderEntryRequestAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeDisableOrderEntryRequestAppendageBody(bytes) ==
    LET disableOrderEntryRequestOptionalField == ReadUIntBE(bytes, 1) IN IF ~disableOrderEntryRequestOptionalField.ok THEN Fail ELSE
    LET disableOrderEntryRequestOptionalValue == DecodeDisableOrderEntryRequestOptionalValue(disableOrderEntryRequestOptionalField.value, disableOrderEntryRequestOptionalField.rest) IN IF ~disableOrderEntryRequestOptionalValue.ok THEN Fail ELSE
    Ok([ disableOrderEntryRequestOptionalValue |-> disableOrderEntryRequestOptionalValue.value ], disableOrderEntryRequestOptionalValue.rest)

DecodeDisableOrderEntryRequestAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeDisableOrderEntryRequestAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroDisableOrderEntryRequestAppendage ==
    [ disableOrderEntryRequestOptionalValue |-> ZeroDisableOrderEntryRequestOptionalValue ]

(* Disable Order Entry Request Appendage at zero, then each field in turn at the values it is checked at *)
CheckedDisableOrderEntryRequestAppendage ==
    { ZeroDisableOrderEntryRequestAppendage }
        \cup { [ZeroDisableOrderEntryRequestAppendage EXCEPT !.disableOrderEntryRequestOptionalValue = one] : one \in CheckedDisableOrderEntryRequestOptionalValue }

(* A run of Disable Order Entry Request Appendage, written one after another *)
RECURSIVE EncodeDisableOrderEntryRequestAppendageList(_)
EncodeDisableOrderEntryRequestAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDisableOrderEntryRequestAppendage(Head(messages)) \o EncodeDisableOrderEntryRequestAppendageList(Tail(messages))

(* As many Disable Order Entry Request Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadDisableOrderEntryRequestAppendageAll(_)
ReadDisableOrderEntryRequestAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeDisableOrderEntryRequestAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDisableOrderEntryRequestAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Disable Order Entry Request Appendage of each kind, for the lists that carry them *)
OneDisableOrderEntryRequestAppendage ==
    { [ZeroDisableOrderEntryRequestAppendage EXCEPT !.disableOrderEntryRequestOptionalValue = [tag |-> UserRefIdxCode3, body |-> ZeroUserRefIdx3]] }

(***************************************************************************)
(* Disable Order Entry Request Message                                     *)
(***************************************************************************)

DisableOrderEntryRequestMessage ==
    [ userRefNum                        : Sample(4),
      firm                              : Sample(4),
      disableOrderEntryRequestAppendage : SampleLists(OneDisableOrderEntryRequestAppendage) ]

EncodeDisableOrderEntryRequestMessage(message) ==
    LET payload == EncodeDisableOrderEntryRequestAppendageList(message.disableOrderEntryRequestAppendage)
    IN  message.userRefNum
            \o message.firm
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeDisableOrderEntryRequestMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET firm == ReadBytes(userRefNum.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(firm.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        disableOrderEntryRequestAppendage == ReadDisableOrderEntryRequestAppendageAll(framed)
    IN  IF ~disableOrderEntryRequestAppendage.ok \/ disableOrderEntryRequestAppendage.rest # << >> THEN Fail ELSE
    Ok([ userRefNum                        |-> userRefNum.value,
         firm                              |-> firm.value,
         disableOrderEntryRequestAppendage |-> disableOrderEntryRequestAppendage.value ], beyond)

ZeroDisableOrderEntryRequestMessage ==
    [ userRefNum                        |-> [i \in 1 .. 4 |-> 0],
      firm                              |-> [i \in 1 .. 4 |-> 0],
      disableOrderEntryRequestAppendage |-> << >> ]

(* Disable Order Entry Request Message at zero, then each field in turn at the values it is checked at *)
CheckedDisableOrderEntryRequestMessage ==
    { ZeroDisableOrderEntryRequestMessage }
        \cup { [ZeroDisableOrderEntryRequestMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroDisableOrderEntryRequestMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroDisableOrderEntryRequestMessage EXCEPT !.disableOrderEntryRequestAppendage = one] : one \in SampleLists(OneDisableOrderEntryRequestAppendage) }

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
(* Enable Order Entry Request Optional Value, selected by Enable Order     *)
(* Entry Request Optional Field                                            *)
(***************************************************************************)

UserRefIdxCode4 == 28  \* 0x1c

EnableOrderEntryRequestOptionalValue ==
    [ tag : {UserRefIdxCode4}, body : UserRefIdx4 ]

EncodeEnableOrderEntryRequestOptionalValue(message) ==
    CASE message.tag = UserRefIdxCode4 -> EncodeUserRefIdx4(message.body)

DecodeEnableOrderEntryRequestOptionalValue(tag, bytes) ==
    LET read ==
            CASE tag = UserRefIdxCode4 -> DecodeUserRefIdx4(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroEnableOrderEntryRequestOptionalValue == [tag |-> UserRefIdxCode4, body |-> ZeroUserRefIdx4]

(* Each Enable Order Entry Request Optional Value in turn, at the values the message it names is checked at *)
CheckedEnableOrderEntryRequestOptionalValue ==
    { [tag |-> UserRefIdxCode4, body |-> one] : one \in CheckedUserRefIdx4 }

(***************************************************************************)
(* Enable Order Entry Request Appendage, framed by Optional Field Length   *)
(***************************************************************************)

EnableOrderEntryRequestAppendage ==
    [ enableOrderEntryRequestOptionalValue : EnableOrderEntryRequestOptionalValue ]

EncodeEnableOrderEntryRequestAppendageBody(message) ==
    EncodeUIntBE(message.enableOrderEntryRequestOptionalValue.tag, 1)
        \o EncodeEnableOrderEntryRequestOptionalValue(message.enableOrderEntryRequestOptionalValue)

(* Optional Field Length counts the bytes it frames, so it is written from them *)
EncodeEnableOrderEntryRequestAppendage(message) ==
    LET body == EncodeEnableOrderEntryRequestAppendageBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeEnableOrderEntryRequestAppendageBody(bytes) ==
    LET enableOrderEntryRequestOptionalField == ReadUIntBE(bytes, 1) IN IF ~enableOrderEntryRequestOptionalField.ok THEN Fail ELSE
    LET enableOrderEntryRequestOptionalValue == DecodeEnableOrderEntryRequestOptionalValue(enableOrderEntryRequestOptionalField.value, enableOrderEntryRequestOptionalField.rest) IN IF ~enableOrderEntryRequestOptionalValue.ok THEN Fail ELSE
    Ok([ enableOrderEntryRequestOptionalValue |-> enableOrderEntryRequestOptionalValue.value ], enableOrderEntryRequestOptionalValue.rest)

DecodeEnableOrderEntryRequestAppendage(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeEnableOrderEntryRequestAppendageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroEnableOrderEntryRequestAppendage ==
    [ enableOrderEntryRequestOptionalValue |-> ZeroEnableOrderEntryRequestOptionalValue ]

(* Enable Order Entry Request Appendage at zero, then each field in turn at the values it is checked at *)
CheckedEnableOrderEntryRequestAppendage ==
    { ZeroEnableOrderEntryRequestAppendage }
        \cup { [ZeroEnableOrderEntryRequestAppendage EXCEPT !.enableOrderEntryRequestOptionalValue = one] : one \in CheckedEnableOrderEntryRequestOptionalValue }

(* A run of Enable Order Entry Request Appendage, written one after another *)
RECURSIVE EncodeEnableOrderEntryRequestAppendageList(_)
EncodeEnableOrderEntryRequestAppendageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeEnableOrderEntryRequestAppendage(Head(messages)) \o EncodeEnableOrderEntryRequestAppendageList(Tail(messages))

(* As many Enable Order Entry Request Appendage as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadEnableOrderEntryRequestAppendageAll(_)
ReadEnableOrderEntryRequestAppendageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeEnableOrderEntryRequestAppendage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadEnableOrderEntryRequestAppendageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Enable Order Entry Request Appendage of each kind, for the lists that carry them *)
OneEnableOrderEntryRequestAppendage ==
    { [ZeroEnableOrderEntryRequestAppendage EXCEPT !.enableOrderEntryRequestOptionalValue = [tag |-> UserRefIdxCode4, body |-> ZeroUserRefIdx4]] }

(***************************************************************************)
(* Enable Order Entry Request Message                                      *)
(***************************************************************************)

EnableOrderEntryRequestMessage ==
    [ userRefNum                       : Sample(4),
      firm                             : Sample(4),
      enableOrderEntryRequestAppendage : SampleLists(OneEnableOrderEntryRequestAppendage) ]

EncodeEnableOrderEntryRequestMessage(message) ==
    LET payload == EncodeEnableOrderEntryRequestAppendageList(message.enableOrderEntryRequestAppendage)
    IN  message.userRefNum
            \o message.firm
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeEnableOrderEntryRequestMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET firm == ReadBytes(userRefNum.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(firm.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        enableOrderEntryRequestAppendage == ReadEnableOrderEntryRequestAppendageAll(framed)
    IN  IF ~enableOrderEntryRequestAppendage.ok \/ enableOrderEntryRequestAppendage.rest # << >> THEN Fail ELSE
    Ok([ userRefNum                       |-> userRefNum.value,
         firm                             |-> firm.value,
         enableOrderEntryRequestAppendage |-> enableOrderEntryRequestAppendage.value ], beyond)

ZeroEnableOrderEntryRequestMessage ==
    [ userRefNum                       |-> [i \in 1 .. 4 |-> 0],
      firm                             |-> [i \in 1 .. 4 |-> 0],
      enableOrderEntryRequestAppendage |-> << >> ]

(* Enable Order Entry Request Message at zero, then each field in turn at the values it is checked at *)
CheckedEnableOrderEntryRequestMessage ==
    { ZeroEnableOrderEntryRequestMessage }
        \cup { [ZeroEnableOrderEntryRequestMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroEnableOrderEntryRequestMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroEnableOrderEntryRequestMessage EXCEPT !.enableOrderEntryRequestAppendage = one] : one \in SampleLists(OneEnableOrderEntryRequestAppendage) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

EnterOrderMessageCode == 79  \* "O"
ReplaceOrderMessageCode == 85  \* "U"
CancelOrderMessageCode == 88  \* "X"
ModifyOrderMessageCode == 77  \* "M"
AccountQueryMessageCode == 81  \* "Q"
MassCancelRequestMessageCode == 67  \* "C"
DisableOrderEntryRequestMessageCode == 68  \* "D"
EnableOrderEntryRequestMessageCode == 69  \* "E"

UnsequencedMessage ==
    [ tag : {EnterOrderMessageCode}, body : EnterOrderMessage ]
        \cup [ tag : {ReplaceOrderMessageCode}, body : ReplaceOrderMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {AccountQueryMessageCode}, body : AccountQueryMessage ]
        \cup [ tag : {MassCancelRequestMessageCode}, body : MassCancelRequestMessage ]
        \cup [ tag : {DisableOrderEntryRequestMessageCode}, body : DisableOrderEntryRequestMessage ]
        \cup [ tag : {EnableOrderEntryRequestMessageCode}, body : EnableOrderEntryRequestMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = EnterOrderMessageCode -> EncodeEnterOrderMessage(message.body)
      [] message.tag = ReplaceOrderMessageCode -> EncodeReplaceOrderMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = AccountQueryMessageCode -> EncodeAccountQueryMessage(message.body)
      [] message.tag = MassCancelRequestMessageCode -> EncodeMassCancelRequestMessage(message.body)
      [] message.tag = DisableOrderEntryRequestMessageCode -> EncodeDisableOrderEntryRequestMessage(message.body)
      [] message.tag = EnableOrderEntryRequestMessageCode -> EncodeEnableOrderEntryRequestMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = EnterOrderMessageCode -> DecodeEnterOrderMessage(bytes)
              [] tag = ReplaceOrderMessageCode -> DecodeReplaceOrderMessage(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = AccountQueryMessageCode -> DecodeAccountQueryMessage(bytes)
              [] tag = MassCancelRequestMessageCode -> DecodeMassCancelRequestMessage(bytes)
              [] tag = DisableOrderEntryRequestMessageCode -> DecodeDisableOrderEntryRequestMessage(bytes)
              [] tag = EnableOrderEntryRequestMessageCode -> DecodeEnableOrderEntryRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> EnterOrderMessageCode, body |-> ZeroEnterOrderMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> EnterOrderMessageCode, body |-> one] : one \in CheckedEnterOrderMessage }
        \cup { [tag |-> ReplaceOrderMessageCode, body |-> one] : one \in CheckedReplaceOrderMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> AccountQueryMessageCode, body |-> one] : one \in CheckedAccountQueryMessage }
        \cup { [tag |-> MassCancelRequestMessageCode, body |-> one] : one \in CheckedMassCancelRequestMessage }
        \cup { [tag |-> DisableOrderEntryRequestMessageCode, body |-> one] : one \in CheckedDisableOrderEntryRequestMessage }
        \cup { [tag |-> EnableOrderEntryRequestMessageCode, body |-> one] : one \in CheckedEnableOrderEntryRequestMessage }

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
RoundTripPriceType ==
    \A message \in CheckedPriceType :
        LET read == DecodePriceType(EncodePriceType(message))
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

(* Every Replace Order Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceOrderAppendage ==
    \A message \in CheckedReplaceOrderAppendage :
        LET read == DecodeReplaceOrderAppendage(EncodeReplaceOrderAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replace Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceOrderMessage ==
    \A message \in CheckedReplaceOrderMessage :
        LET read == DecodeReplaceOrderMessage(EncodeReplaceOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderMessage ==
    \A message \in CheckedCancelOrderMessage :
        LET read == DecodeCancelOrderMessage(EncodeCancelOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
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

(* Every Account Query Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryAppendage ==
    \A message \in CheckedAccountQueryAppendage :
        LET read == DecodeAccountQueryAppendage(EncodeAccountQueryAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Query Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryMessageTail ==
    \A message \in CheckedAccountQueryMessageTail :
        LET read == DecodeAccountQueryMessageTail(EncodeAccountQueryMessageTail(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Query Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryMessage ==
    \A message \in CheckedAccountQueryMessage :
        LET read == DecodeAccountQueryMessage(EncodeAccountQueryMessage(message))
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
RoundTripUserRefIdx2 ==
    \A message \in CheckedUserRefIdx2 :
        LET read == DecodeUserRefIdx2(EncodeUserRefIdx2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Request Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRequestAppendage ==
    \A message \in CheckedMassCancelRequestAppendage :
        LET read == DecodeMassCancelRequestAppendage(EncodeMassCancelRequestAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelRequestMessage ==
    \A message \in CheckedMassCancelRequestMessage :
        LET read == DecodeMassCancelRequestMessage(EncodeMassCancelRequestMessage(message))
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

(* Every Disable Order Entry Request Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripDisableOrderEntryRequestAppendage ==
    \A message \in CheckedDisableOrderEntryRequestAppendage :
        LET read == DecodeDisableOrderEntryRequestAppendage(EncodeDisableOrderEntryRequestAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disable Order Entry Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDisableOrderEntryRequestMessage ==
    \A message \in CheckedDisableOrderEntryRequestMessage :
        LET read == DecodeDisableOrderEntryRequestMessage(EncodeDisableOrderEntryRequestMessage(message))
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

(* Every Enable Order Entry Request Appendage decodes back to what was encoded, and leaves nothing over *)
RoundTripEnableOrderEntryRequestAppendage ==
    \A message \in CheckedEnableOrderEntryRequestAppendage :
        LET read == DecodeEnableOrderEntryRequestAppendage(EncodeEnableOrderEntryRequestAppendage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enable Order Entry Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEnableOrderEntryRequestMessage ==
    \A message \in CheckedEnableOrderEntryRequestMessage :
        LET read == DecodeEnableOrderEntryRequestMessage(EncodeEnableOrderEntryRequestMessage(message))
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

(* A Replace Order Optional Value is selected by the Replace Order Optional Field it is written under *)
SelectsReplaceOrderOptionalValue ==
    \A message \in CheckedReplaceOrderOptionalValue :
        LET read == DecodeReplaceOrderOptionalValue(message.tag, EncodeReplaceOrderOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Account Query Optional Value is selected by the Account Query Optional Field it is written under *)
SelectsAccountQueryOptionalValue ==
    \A message \in CheckedAccountQueryOptionalValue :
        LET read == DecodeAccountQueryOptionalValue(message.tag, EncodeAccountQueryOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Mass Cancel Request Optional Value is selected by the Mass Cancel Request Optional Field it is written under *)
SelectsMassCancelRequestOptionalValue ==
    \A message \in CheckedMassCancelRequestOptionalValue :
        LET read == DecodeMassCancelRequestOptionalValue(message.tag, EncodeMassCancelRequestOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Disable Order Entry Request Optional Value is selected by the Disable Order Entry Request Optional Field it is written under *)
SelectsDisableOrderEntryRequestOptionalValue ==
    \A message \in CheckedDisableOrderEntryRequestOptionalValue :
        LET read == DecodeDisableOrderEntryRequestOptionalValue(message.tag, EncodeDisableOrderEntryRequestOptionalValue(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Enable Order Entry Request Optional Value is selected by the Enable Order Entry Request Optional Field it is written under *)
SelectsEnableOrderEntryRequestOptionalValue ==
    \A message \in CheckedEnableOrderEntryRequestOptionalValue :
        LET read == DecodeEnableOrderEntryRequestOptionalValue(message.tag, EncodeEnableOrderEntryRequestOptionalValue(message))
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
FramesReplaceOrderAppendage ==
    \A message \in CheckedReplaceOrderAppendage :
        LET bytes == EncodeReplaceOrderAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesAccountQueryAppendage ==
    \A message \in CheckedAccountQueryAppendage :
        LET bytes == EncodeAccountQueryAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesMassCancelRequestAppendage ==
    \A message \in CheckedMassCancelRequestAppendage :
        LET bytes == EncodeMassCancelRequestAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesDisableOrderEntryRequestAppendage ==
    \A message \in CheckedDisableOrderEntryRequestAppendage :
        LET bytes == EncodeDisableOrderEntryRequestAppendage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Optional Field Length is written from the bytes it frames *)
FramesEnableOrderEntryRequestAppendage ==
    \A message \in CheckedEnableOrderEntryRequestAppendage :
        LET bytes == EncodeEnableOrderEntryRequestAppendage(message)
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
