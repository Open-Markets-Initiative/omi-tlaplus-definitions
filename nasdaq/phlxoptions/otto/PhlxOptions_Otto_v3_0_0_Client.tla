------------------ MODULE PhlxOptions_Otto_v3_0_0_Client -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Ouch to Trade Options v3.0.0                                   *)
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
(* Flex Leg Prices: 16 bytes                                               *)
(***************************************************************************)

FlexLegPrices ==
    [ legPrices : Sample(8),
      reserved8 : Sample(8) ]

EncodeFlexLegPrices(message) ==
    message.legPrices
        \o message.reserved8

DecodeFlexLegPrices(bytes) ==
    LET legPrices == ReadBytes(bytes, 8) IN IF ~legPrices.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(legPrices.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ legPrices |-> legPrices.value,
         reserved8 |-> reserved8.value ], reserved8.rest)

ZeroFlexLegPrices ==
    [ legPrices |-> [i \in 1 .. 8 |-> 0],
      reserved8 |-> [i \in 1 .. 8 |-> 0] ]

(* Flex Leg Prices at zero, then each field in turn at the values it is checked at *)
CheckedFlexLegPrices ==
    { ZeroFlexLegPrices }
        \cup { [ZeroFlexLegPrices EXCEPT !.legPrices = one] : one \in Sample(8) }
        \cup { [ZeroFlexLegPrices EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Flex Leg Prices, written one after another *)
RECURSIVE EncodeFlexLegPricesList(_)
EncodeFlexLegPricesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFlexLegPrices(Head(messages)) \o EncodeFlexLegPricesList(Tail(messages))

(* As many Flex Leg Prices as the field that counts them says *)
RECURSIVE ReadFlexLegPricesList(_, _)
ReadFlexLegPricesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFlexLegPrices(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFlexLegPricesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Flex Leg Prices of each kind, for the lists that carry them *)
OneFlexLegPrices == { ZeroFlexLegPrices }

(***************************************************************************)
(* New Order Long Form Message                                             *)
(***************************************************************************)

NewOrderLongFormMessage ==
    [ firmId             : Sample(4),
      instrumentId       : Sample(4),
      clOrdId            : Sample(16),
      cmta               : Sample(4),
      clearingAccount    : Sample(4),
      occAccount         : Sample(4),
      custAcct           : Sample(10),
      preferredParty     : Sample(3),
      aloInst            : Sample(1),
      iso                : Sample(1),
      side               : Sample(1),
      orderType          : Sample(1),
      price              : Sample(8),
      quantity           : Sample(4),
      minQty             : Sample(4),
      tif                : Sample(1),
      capacity           : Sample(1),
      auctionType        : Sample(1),
      auctionId          : Sample(4),
      auctionDuration    : Sample(4),
      disclosureMask     : Sample(1),
      priceProtection    : Sample(1),
      displayQty         : Sample(2),
      displayWhen        : Sample(1),
      displayMethod      : Sample(1),
      displayLowQty      : Sample(2),
      displayHighQty     : Sample(2),
      positionEffectMask : Sample(2),
      stockLegShortSale  : Sample(1),
      stockLegMpid       : Sample(4),
      stockCapacity      : Sample(1),
      reserved9          : Sample(9),
      flexLegPrices      : SampleLists(OneFlexLegPrices) ]

EncodeNewOrderLongFormMessage(message) ==
    message.firmId
        \o message.instrumentId
        \o message.clOrdId
        \o message.cmta
        \o message.clearingAccount
        \o message.occAccount
        \o message.custAcct
        \o message.preferredParty
        \o message.aloInst
        \o message.iso
        \o message.side
        \o message.orderType
        \o message.price
        \o message.quantity
        \o message.minQty
        \o message.tif
        \o message.capacity
        \o message.auctionType
        \o message.auctionId
        \o message.auctionDuration
        \o message.disclosureMask
        \o message.priceProtection
        \o message.displayQty
        \o message.displayWhen
        \o message.displayMethod
        \o message.displayLowQty
        \o message.displayHighQty
        \o message.positionEffectMask
        \o message.stockLegShortSale
        \o message.stockLegMpid
        \o message.stockCapacity
        \o message.reserved9
        \o EncodeUIntBE(Len(message.flexLegPrices), 1)
        \o EncodeFlexLegPricesList(message.flexLegPrices)

DecodeNewOrderLongFormMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(instrumentId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cmta == ReadBytes(clOrdId.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(cmta.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET occAccount == ReadBytes(clearingAccount.rest, 4) IN IF ~occAccount.ok THEN Fail ELSE
    LET custAcct == ReadBytes(occAccount.rest, 10) IN IF ~custAcct.ok THEN Fail ELSE
    LET preferredParty == ReadBytes(custAcct.rest, 3) IN IF ~preferredParty.ok THEN Fail ELSE
    LET aloInst == ReadBytes(preferredParty.rest, 1) IN IF ~aloInst.ok THEN Fail ELSE
    LET iso == ReadBytes(aloInst.rest, 1) IN IF ~iso.ok THEN Fail ELSE
    LET side == ReadBytes(iso.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET minQty == ReadBytes(quantity.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET tif == ReadBytes(minQty.rest, 1) IN IF ~tif.ok THEN Fail ELSE
    LET capacity == ReadBytes(tif.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET auctionType == ReadBytes(capacity.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(auctionType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionDuration == ReadBytes(auctionId.rest, 4) IN IF ~auctionDuration.ok THEN Fail ELSE
    LET disclosureMask == ReadBytes(auctionDuration.rest, 1) IN IF ~disclosureMask.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(disclosureMask.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    LET displayQty == ReadBytes(priceProtection.rest, 2) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayWhen == ReadBytes(displayQty.rest, 1) IN IF ~displayWhen.ok THEN Fail ELSE
    LET displayMethod == ReadBytes(displayWhen.rest, 1) IN IF ~displayMethod.ok THEN Fail ELSE
    LET displayLowQty == ReadBytes(displayMethod.rest, 2) IN IF ~displayLowQty.ok THEN Fail ELSE
    LET displayHighQty == ReadBytes(displayLowQty.rest, 2) IN IF ~displayHighQty.ok THEN Fail ELSE
    LET positionEffectMask == ReadBytes(displayHighQty.rest, 2) IN IF ~positionEffectMask.ok THEN Fail ELSE
    LET stockLegShortSale == ReadBytes(positionEffectMask.rest, 1) IN IF ~stockLegShortSale.ok THEN Fail ELSE
    LET stockLegMpid == ReadBytes(stockLegShortSale.rest, 4) IN IF ~stockLegMpid.ok THEN Fail ELSE
    LET stockCapacity == ReadBytes(stockLegMpid.rest, 1) IN IF ~stockCapacity.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(stockCapacity.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    LET numberOfFlexLegs == ReadUIntBE(reserved9.rest, 1) IN IF ~numberOfFlexLegs.ok THEN Fail ELSE
    LET flexLegPrices == ReadFlexLegPricesList(numberOfFlexLegs.rest, numberOfFlexLegs.value) IN IF ~flexLegPrices.ok THEN Fail ELSE
    Ok([ firmId             |-> firmId.value,
         instrumentId       |-> instrumentId.value,
         clOrdId            |-> clOrdId.value,
         cmta               |-> cmta.value,
         clearingAccount    |-> clearingAccount.value,
         occAccount         |-> occAccount.value,
         custAcct           |-> custAcct.value,
         preferredParty     |-> preferredParty.value,
         aloInst            |-> aloInst.value,
         iso                |-> iso.value,
         side               |-> side.value,
         orderType          |-> orderType.value,
         price              |-> price.value,
         quantity           |-> quantity.value,
         minQty             |-> minQty.value,
         tif                |-> tif.value,
         capacity           |-> capacity.value,
         auctionType        |-> auctionType.value,
         auctionId          |-> auctionId.value,
         auctionDuration    |-> auctionDuration.value,
         disclosureMask     |-> disclosureMask.value,
         priceProtection    |-> priceProtection.value,
         displayQty         |-> displayQty.value,
         displayWhen        |-> displayWhen.value,
         displayMethod      |-> displayMethod.value,
         displayLowQty      |-> displayLowQty.value,
         displayHighQty     |-> displayHighQty.value,
         positionEffectMask |-> positionEffectMask.value,
         stockLegShortSale  |-> stockLegShortSale.value,
         stockLegMpid       |-> stockLegMpid.value,
         stockCapacity      |-> stockCapacity.value,
         reserved9          |-> reserved9.value,
         flexLegPrices      |-> flexLegPrices.value ], flexLegPrices.rest)

ZeroNewOrderLongFormMessage ==
    [ firmId             |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      clOrdId            |-> [i \in 1 .. 16 |-> 0],
      cmta               |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      occAccount         |-> [i \in 1 .. 4 |-> 0],
      custAcct           |-> [i \in 1 .. 10 |-> 0],
      preferredParty     |-> [i \in 1 .. 3 |-> 0],
      aloInst            |-> [i \in 1 .. 1 |-> 0],
      iso                |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      orderType          |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      quantity           |-> [i \in 1 .. 4 |-> 0],
      minQty             |-> [i \in 1 .. 4 |-> 0],
      tif                |-> [i \in 1 .. 1 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      auctionType        |-> [i \in 1 .. 1 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      auctionDuration    |-> [i \in 1 .. 4 |-> 0],
      disclosureMask     |-> [i \in 1 .. 1 |-> 0],
      priceProtection    |-> [i \in 1 .. 1 |-> 0],
      displayQty         |-> [i \in 1 .. 2 |-> 0],
      displayWhen        |-> [i \in 1 .. 1 |-> 0],
      displayMethod      |-> [i \in 1 .. 1 |-> 0],
      displayLowQty      |-> [i \in 1 .. 2 |-> 0],
      displayHighQty     |-> [i \in 1 .. 2 |-> 0],
      positionEffectMask |-> [i \in 1 .. 2 |-> 0],
      stockLegShortSale  |-> [i \in 1 .. 1 |-> 0],
      stockLegMpid       |-> [i \in 1 .. 4 |-> 0],
      stockCapacity      |-> [i \in 1 .. 1 |-> 0],
      reserved9          |-> [i \in 1 .. 9 |-> 0],
      flexLegPrices      |-> << >> ]

(* New Order Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderLongFormMessage ==
    { ZeroNewOrderLongFormMessage }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.cmta = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.occAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.custAcct = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.preferredParty = one] : one \in Sample(3) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.aloInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.iso = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.tif = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.auctionDuration = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.disclosureMask = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.displayQty = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.displayWhen = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.displayMethod = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.displayLowQty = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.displayHighQty = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.positionEffectMask = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.stockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.stockLegMpid = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.stockCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }
        \cup { [ZeroNewOrderLongFormMessage EXCEPT !.flexLegPrices = one] : one \in SampleLists(OneFlexLegPrices) }

(***************************************************************************)
(* New Order Short Form Message: 49 bytes                                  *)
(***************************************************************************)

NewOrderShortFormMessage ==
    [ firmId             : Sample(4),
      instrumentId       : Sample(4),
      clOrdId            : Sample(16),
      aloInst            : Sample(1),
      iso                : Sample(1),
      side               : Sample(1),
      orderType          : Sample(1),
      price              : Sample(8),
      quantityShort      : Sample(2),
      tif                : Sample(1),
      capacity           : Sample(1),
      auctionType        : Sample(1),
      auctionId          : Sample(4),
      priceProtection    : Sample(1),
      positionEffectMask : Sample(2),
      stockCapacity      : Sample(1) ]

EncodeNewOrderShortFormMessage(message) ==
    message.firmId
        \o message.instrumentId
        \o message.clOrdId
        \o message.aloInst
        \o message.iso
        \o message.side
        \o message.orderType
        \o message.price
        \o message.quantityShort
        \o message.tif
        \o message.capacity
        \o message.auctionType
        \o message.auctionId
        \o message.priceProtection
        \o message.positionEffectMask
        \o message.stockCapacity

DecodeNewOrderShortFormMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(instrumentId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET aloInst == ReadBytes(clOrdId.rest, 1) IN IF ~aloInst.ok THEN Fail ELSE
    LET iso == ReadBytes(aloInst.rest, 1) IN IF ~iso.ok THEN Fail ELSE
    LET side == ReadBytes(iso.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(price.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET tif == ReadBytes(quantityShort.rest, 1) IN IF ~tif.ok THEN Fail ELSE
    LET capacity == ReadBytes(tif.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET auctionType == ReadBytes(capacity.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(auctionType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(auctionId.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    LET positionEffectMask == ReadBytes(priceProtection.rest, 2) IN IF ~positionEffectMask.ok THEN Fail ELSE
    LET stockCapacity == ReadBytes(positionEffectMask.rest, 1) IN IF ~stockCapacity.ok THEN Fail ELSE
    Ok([ firmId             |-> firmId.value,
         instrumentId       |-> instrumentId.value,
         clOrdId            |-> clOrdId.value,
         aloInst            |-> aloInst.value,
         iso                |-> iso.value,
         side               |-> side.value,
         orderType          |-> orderType.value,
         price              |-> price.value,
         quantityShort      |-> quantityShort.value,
         tif                |-> tif.value,
         capacity           |-> capacity.value,
         auctionType        |-> auctionType.value,
         auctionId          |-> auctionId.value,
         priceProtection    |-> priceProtection.value,
         positionEffectMask |-> positionEffectMask.value,
         stockCapacity      |-> stockCapacity.value ], stockCapacity.rest)

ZeroNewOrderShortFormMessage ==
    [ firmId             |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      clOrdId            |-> [i \in 1 .. 16 |-> 0],
      aloInst            |-> [i \in 1 .. 1 |-> 0],
      iso                |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      orderType          |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      quantityShort      |-> [i \in 1 .. 2 |-> 0],
      tif                |-> [i \in 1 .. 1 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      auctionType        |-> [i \in 1 .. 1 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      priceProtection    |-> [i \in 1 .. 1 |-> 0],
      positionEffectMask |-> [i \in 1 .. 2 |-> 0],
      stockCapacity      |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderShortFormMessage ==
    { ZeroNewOrderShortFormMessage }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.aloInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.iso = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.tif = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.positionEffectMask = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderShortFormMessage EXCEPT !.stockCapacity = one] : one \in Sample(1) }

(***************************************************************************)
(* Replace Order Message: 61 bytes                                         *)
(***************************************************************************)

ReplaceOrderMessage ==
    [ firmId          : Sample(4),
      origClOrdId     : Sample(16),
      clOrdId         : Sample(16),
      quantity        : Sample(4),
      orderType       : Sample(1),
      price           : Sample(8),
      tif             : Sample(1),
      custAcct        : Sample(10),
      priceProtection : Sample(1) ]

EncodeReplaceOrderMessage(message) ==
    message.firmId
        \o message.origClOrdId
        \o message.clOrdId
        \o message.quantity
        \o message.orderType
        \o message.price
        \o message.tif
        \o message.custAcct
        \o message.priceProtection

DecodeReplaceOrderMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(firmId.rest, 16) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(origClOrdId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET quantity == ReadBytes(clOrdId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderType == ReadBytes(quantity.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tif == ReadBytes(price.rest, 1) IN IF ~tif.ok THEN Fail ELSE
    LET custAcct == ReadBytes(tif.rest, 10) IN IF ~custAcct.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(custAcct.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    Ok([ firmId          |-> firmId.value,
         origClOrdId     |-> origClOrdId.value,
         clOrdId         |-> clOrdId.value,
         quantity        |-> quantity.value,
         orderType       |-> orderType.value,
         price           |-> price.value,
         tif             |-> tif.value,
         custAcct        |-> custAcct.value,
         priceProtection |-> priceProtection.value ], priceProtection.rest)

ZeroReplaceOrderMessage ==
    [ firmId          |-> [i \in 1 .. 4 |-> 0],
      origClOrdId     |-> [i \in 1 .. 16 |-> 0],
      clOrdId         |-> [i \in 1 .. 16 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      orderType       |-> [i \in 1 .. 1 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      tif             |-> [i \in 1 .. 1 |-> 0],
      custAcct        |-> [i \in 1 .. 10 |-> 0],
      priceProtection |-> [i \in 1 .. 1 |-> 0] ]

(* Replace Order Message at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderMessage ==
    { ZeroReplaceOrderMessage }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.origClOrdId = one] : one \in Sample(16) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.tif = one] : one \in Sample(1) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.custAcct = one] : one \in Sample(10) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Order Message: 20 bytes                                          *)
(***************************************************************************)

CancelOrderMessage ==
    [ firmId  : Sample(4),
      clOrdId : Sample(16) ]

EncodeCancelOrderMessage(message) ==
    message.firmId
        \o message.clOrdId

DecodeCancelOrderMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(firmId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    Ok([ firmId  |-> firmId.value,
         clOrdId |-> clOrdId.value ], clOrdId.rest)

ZeroCancelOrderMessage ==
    [ firmId  |-> [i \in 1 .. 4 |-> 0],
      clOrdId |-> [i \in 1 .. 16 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }

(***************************************************************************)
(* Mass Cancel Message: 41 bytes                                           *)
(***************************************************************************)

MassCancelMessage ==
    [ firmId           : Sample(4),
      clRequestId      : Sample(16),
      instrumentType   : Sample(1),
      scope            : Sample(1),
      productId        : Sample(2),
      instrumentId     : Sample(4),
      underlyingSymbol : Sample(13) ]

EncodeMassCancelMessage(message) ==
    message.firmId
        \o message.clRequestId
        \o message.instrumentType
        \o message.scope
        \o message.productId
        \o message.instrumentId
        \o message.underlyingSymbol

DecodeMassCancelMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(firmId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(clRequestId.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET scope == ReadBytes(instrumentType.rest, 1) IN IF ~scope.ok THEN Fail ELSE
    LET productId == ReadBytes(scope.rest, 2) IN IF ~productId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(productId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(instrumentId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    Ok([ firmId           |-> firmId.value,
         clRequestId      |-> clRequestId.value,
         instrumentType   |-> instrumentType.value,
         scope            |-> scope.value,
         productId        |-> productId.value,
         instrumentId     |-> instrumentId.value,
         underlyingSymbol |-> underlyingSymbol.value ], underlyingSymbol.rest)

ZeroMassCancelMessage ==
    [ firmId           |-> [i \in 1 .. 4 |-> 0],
      clRequestId      |-> [i \in 1 .. 16 |-> 0],
      instrumentType   |-> [i \in 1 .. 1 |-> 0],
      scope            |-> [i \in 1 .. 1 |-> 0],
      productId        |-> [i \in 1 .. 2 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0] ]

(* Mass Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelMessage ==
    { ZeroMassCancelMessage }
        \cup { [ZeroMassCancelMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }
        \cup { [ZeroMassCancelMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelMessage EXCEPT !.scope = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelMessage EXCEPT !.productId = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }

(***************************************************************************)
(* Flex Leg Prices: 16 bytes                                               *)
(***************************************************************************)

FlexLegPrices2 ==
    [ legPrices : Sample(8),
      reserved8 : Sample(8) ]

EncodeFlexLegPrices2(message) ==
    message.legPrices
        \o message.reserved8

DecodeFlexLegPrices2(bytes) ==
    LET legPrices == ReadBytes(bytes, 8) IN IF ~legPrices.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(legPrices.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ legPrices |-> legPrices.value,
         reserved8 |-> reserved8.value ], reserved8.rest)

ZeroFlexLegPrices2 ==
    [ legPrices |-> [i \in 1 .. 8 |-> 0],
      reserved8 |-> [i \in 1 .. 8 |-> 0] ]

(* Flex Leg Prices at zero, then each field in turn at the values it is checked at *)
CheckedFlexLegPrices2 ==
    { ZeroFlexLegPrices2 }
        \cup { [ZeroFlexLegPrices2 EXCEPT !.legPrices = one] : one \in Sample(8) }
        \cup { [ZeroFlexLegPrices2 EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Flex Leg Prices, written one after another *)
RECURSIVE EncodeFlexLegPrices2List(_)
EncodeFlexLegPrices2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFlexLegPrices2(Head(messages)) \o EncodeFlexLegPrices2List(Tail(messages))

(* As many Flex Leg Prices as the field that counts them says *)
RECURSIVE ReadFlexLegPrices2List(_, _)
ReadFlexLegPrices2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFlexLegPrices2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFlexLegPrices2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Flex Leg Prices of each kind, for the lists that carry them *)
OneFlexLegPrices2 == { ZeroFlexLegPrices2 }

(***************************************************************************)
(* New Cross Order Message                                                 *)
(***************************************************************************)

NewCrossOrderMessage ==
    [ firmId                    : Sample(4),
      instrumentId              : Sample(4),
      crossType                 : Sample(1),
      auctionType               : Sample(1),
      auctionAllocPct           : Sample(1),
      side                      : Sample(1),
      iso                       : Sample(1),
      priceProtection           : Sample(1),
      effectiveTime             : Sample(8),
      disclosureMask            : Sample(1),
      auctionDuration           : Sample(4),
      reserved9                 : Sample(9),
      primaryClOrdId            : Sample(16),
      primaryCmta               : Sample(4),
      primaryClearingAccount    : Sample(4),
      primaryOccAccount         : Sample(4),
      primaryCustAcct           : Sample(10),
      primaryPrice              : Sample(8),
      primaryQuantity           : Sample(4),
      primaryCapacity           : Sample(1),
      primaryPositionEffectMask : Sample(2),
      primaryStockLegShortSale  : Sample(1),
      primaryStockLegMpid       : Sample(4),
      primaryStockCapacity      : Sample(1),
      contraClOrdId             : Sample(16),
      contraCmta                : Sample(4),
      contraClearingAccount     : Sample(4),
      contraOccAccount          : Sample(4),
      contraCustAcct            : Sample(10),
      contraOrderType           : Sample(1),
      contraPrice               : Sample(8),
      contraQuantity            : Sample(4),
      contraCapacity            : Sample(1),
      contraPositionEffectMask  : Sample(2),
      contraStockLegShortSale   : Sample(1),
      contraStockLegMpid        : Sample(4),
      contraStockCapacity       : Sample(1),
      flexLegPrices             : SampleLists(OneFlexLegPrices2) ]

EncodeNewCrossOrderMessage(message) ==
    message.firmId
        \o message.instrumentId
        \o message.crossType
        \o message.auctionType
        \o message.auctionAllocPct
        \o message.side
        \o message.iso
        \o message.priceProtection
        \o message.effectiveTime
        \o message.disclosureMask
        \o message.auctionDuration
        \o message.reserved9
        \o message.primaryClOrdId
        \o message.primaryCmta
        \o message.primaryClearingAccount
        \o message.primaryOccAccount
        \o message.primaryCustAcct
        \o message.primaryPrice
        \o message.primaryQuantity
        \o message.primaryCapacity
        \o message.primaryPositionEffectMask
        \o message.primaryStockLegShortSale
        \o message.primaryStockLegMpid
        \o message.primaryStockCapacity
        \o message.contraClOrdId
        \o message.contraCmta
        \o message.contraClearingAccount
        \o message.contraOccAccount
        \o message.contraCustAcct
        \o message.contraOrderType
        \o message.contraPrice
        \o message.contraQuantity
        \o message.contraCapacity
        \o message.contraPositionEffectMask
        \o message.contraStockLegShortSale
        \o message.contraStockLegMpid
        \o message.contraStockCapacity
        \o EncodeUIntBE(Len(message.flexLegPrices), 1)
        \o EncodeFlexLegPrices2List(message.flexLegPrices)

DecodeNewCrossOrderMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET crossType == ReadBytes(instrumentId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET auctionType == ReadBytes(crossType.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionAllocPct == ReadBytes(auctionType.rest, 1) IN IF ~auctionAllocPct.ok THEN Fail ELSE
    LET side == ReadBytes(auctionAllocPct.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET iso == ReadBytes(side.rest, 1) IN IF ~iso.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(iso.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    LET effectiveTime == ReadBytes(priceProtection.rest, 8) IN IF ~effectiveTime.ok THEN Fail ELSE
    LET disclosureMask == ReadBytes(effectiveTime.rest, 1) IN IF ~disclosureMask.ok THEN Fail ELSE
    LET auctionDuration == ReadBytes(disclosureMask.rest, 4) IN IF ~auctionDuration.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(auctionDuration.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    LET primaryClOrdId == ReadBytes(reserved9.rest, 16) IN IF ~primaryClOrdId.ok THEN Fail ELSE
    LET primaryCmta == ReadBytes(primaryClOrdId.rest, 4) IN IF ~primaryCmta.ok THEN Fail ELSE
    LET primaryClearingAccount == ReadBytes(primaryCmta.rest, 4) IN IF ~primaryClearingAccount.ok THEN Fail ELSE
    LET primaryOccAccount == ReadBytes(primaryClearingAccount.rest, 4) IN IF ~primaryOccAccount.ok THEN Fail ELSE
    LET primaryCustAcct == ReadBytes(primaryOccAccount.rest, 10) IN IF ~primaryCustAcct.ok THEN Fail ELSE
    LET primaryPrice == ReadBytes(primaryCustAcct.rest, 8) IN IF ~primaryPrice.ok THEN Fail ELSE
    LET primaryQuantity == ReadBytes(primaryPrice.rest, 4) IN IF ~primaryQuantity.ok THEN Fail ELSE
    LET primaryCapacity == ReadBytes(primaryQuantity.rest, 1) IN IF ~primaryCapacity.ok THEN Fail ELSE
    LET primaryPositionEffectMask == ReadBytes(primaryCapacity.rest, 2) IN IF ~primaryPositionEffectMask.ok THEN Fail ELSE
    LET primaryStockLegShortSale == ReadBytes(primaryPositionEffectMask.rest, 1) IN IF ~primaryStockLegShortSale.ok THEN Fail ELSE
    LET primaryStockLegMpid == ReadBytes(primaryStockLegShortSale.rest, 4) IN IF ~primaryStockLegMpid.ok THEN Fail ELSE
    LET primaryStockCapacity == ReadBytes(primaryStockLegMpid.rest, 1) IN IF ~primaryStockCapacity.ok THEN Fail ELSE
    LET contraClOrdId == ReadBytes(primaryStockCapacity.rest, 16) IN IF ~contraClOrdId.ok THEN Fail ELSE
    LET contraCmta == ReadBytes(contraClOrdId.rest, 4) IN IF ~contraCmta.ok THEN Fail ELSE
    LET contraClearingAccount == ReadBytes(contraCmta.rest, 4) IN IF ~contraClearingAccount.ok THEN Fail ELSE
    LET contraOccAccount == ReadBytes(contraClearingAccount.rest, 4) IN IF ~contraOccAccount.ok THEN Fail ELSE
    LET contraCustAcct == ReadBytes(contraOccAccount.rest, 10) IN IF ~contraCustAcct.ok THEN Fail ELSE
    LET contraOrderType == ReadBytes(contraCustAcct.rest, 1) IN IF ~contraOrderType.ok THEN Fail ELSE
    LET contraPrice == ReadBytes(contraOrderType.rest, 8) IN IF ~contraPrice.ok THEN Fail ELSE
    LET contraQuantity == ReadBytes(contraPrice.rest, 4) IN IF ~contraQuantity.ok THEN Fail ELSE
    LET contraCapacity == ReadBytes(contraQuantity.rest, 1) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET contraPositionEffectMask == ReadBytes(contraCapacity.rest, 2) IN IF ~contraPositionEffectMask.ok THEN Fail ELSE
    LET contraStockLegShortSale == ReadBytes(contraPositionEffectMask.rest, 1) IN IF ~contraStockLegShortSale.ok THEN Fail ELSE
    LET contraStockLegMpid == ReadBytes(contraStockLegShortSale.rest, 4) IN IF ~contraStockLegMpid.ok THEN Fail ELSE
    LET contraStockCapacity == ReadBytes(contraStockLegMpid.rest, 1) IN IF ~contraStockCapacity.ok THEN Fail ELSE
    LET numberOfFlexLegs == ReadUIntBE(contraStockCapacity.rest, 1) IN IF ~numberOfFlexLegs.ok THEN Fail ELSE
    LET flexLegPrices == ReadFlexLegPrices2List(numberOfFlexLegs.rest, numberOfFlexLegs.value) IN IF ~flexLegPrices.ok THEN Fail ELSE
    Ok([ firmId                    |-> firmId.value,
         instrumentId              |-> instrumentId.value,
         crossType                 |-> crossType.value,
         auctionType               |-> auctionType.value,
         auctionAllocPct           |-> auctionAllocPct.value,
         side                      |-> side.value,
         iso                       |-> iso.value,
         priceProtection           |-> priceProtection.value,
         effectiveTime             |-> effectiveTime.value,
         disclosureMask            |-> disclosureMask.value,
         auctionDuration           |-> auctionDuration.value,
         reserved9                 |-> reserved9.value,
         primaryClOrdId            |-> primaryClOrdId.value,
         primaryCmta               |-> primaryCmta.value,
         primaryClearingAccount    |-> primaryClearingAccount.value,
         primaryOccAccount         |-> primaryOccAccount.value,
         primaryCustAcct           |-> primaryCustAcct.value,
         primaryPrice              |-> primaryPrice.value,
         primaryQuantity           |-> primaryQuantity.value,
         primaryCapacity           |-> primaryCapacity.value,
         primaryPositionEffectMask |-> primaryPositionEffectMask.value,
         primaryStockLegShortSale  |-> primaryStockLegShortSale.value,
         primaryStockLegMpid       |-> primaryStockLegMpid.value,
         primaryStockCapacity      |-> primaryStockCapacity.value,
         contraClOrdId             |-> contraClOrdId.value,
         contraCmta                |-> contraCmta.value,
         contraClearingAccount     |-> contraClearingAccount.value,
         contraOccAccount          |-> contraOccAccount.value,
         contraCustAcct            |-> contraCustAcct.value,
         contraOrderType           |-> contraOrderType.value,
         contraPrice               |-> contraPrice.value,
         contraQuantity            |-> contraQuantity.value,
         contraCapacity            |-> contraCapacity.value,
         contraPositionEffectMask  |-> contraPositionEffectMask.value,
         contraStockLegShortSale   |-> contraStockLegShortSale.value,
         contraStockLegMpid        |-> contraStockLegMpid.value,
         contraStockCapacity       |-> contraStockCapacity.value,
         flexLegPrices             |-> flexLegPrices.value ], flexLegPrices.rest)

ZeroNewCrossOrderMessage ==
    [ firmId                    |-> [i \in 1 .. 4 |-> 0],
      instrumentId              |-> [i \in 1 .. 4 |-> 0],
      crossType                 |-> [i \in 1 .. 1 |-> 0],
      auctionType               |-> [i \in 1 .. 1 |-> 0],
      auctionAllocPct           |-> [i \in 1 .. 1 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      iso                       |-> [i \in 1 .. 1 |-> 0],
      priceProtection           |-> [i \in 1 .. 1 |-> 0],
      effectiveTime             |-> [i \in 1 .. 8 |-> 0],
      disclosureMask            |-> [i \in 1 .. 1 |-> 0],
      auctionDuration           |-> [i \in 1 .. 4 |-> 0],
      reserved9                 |-> [i \in 1 .. 9 |-> 0],
      primaryClOrdId            |-> [i \in 1 .. 16 |-> 0],
      primaryCmta               |-> [i \in 1 .. 4 |-> 0],
      primaryClearingAccount    |-> [i \in 1 .. 4 |-> 0],
      primaryOccAccount         |-> [i \in 1 .. 4 |-> 0],
      primaryCustAcct           |-> [i \in 1 .. 10 |-> 0],
      primaryPrice              |-> [i \in 1 .. 8 |-> 0],
      primaryQuantity           |-> [i \in 1 .. 4 |-> 0],
      primaryCapacity           |-> [i \in 1 .. 1 |-> 0],
      primaryPositionEffectMask |-> [i \in 1 .. 2 |-> 0],
      primaryStockLegShortSale  |-> [i \in 1 .. 1 |-> 0],
      primaryStockLegMpid       |-> [i \in 1 .. 4 |-> 0],
      primaryStockCapacity      |-> [i \in 1 .. 1 |-> 0],
      contraClOrdId             |-> [i \in 1 .. 16 |-> 0],
      contraCmta                |-> [i \in 1 .. 4 |-> 0],
      contraClearingAccount     |-> [i \in 1 .. 4 |-> 0],
      contraOccAccount          |-> [i \in 1 .. 4 |-> 0],
      contraCustAcct            |-> [i \in 1 .. 10 |-> 0],
      contraOrderType           |-> [i \in 1 .. 1 |-> 0],
      contraPrice               |-> [i \in 1 .. 8 |-> 0],
      contraQuantity            |-> [i \in 1 .. 4 |-> 0],
      contraCapacity            |-> [i \in 1 .. 1 |-> 0],
      contraPositionEffectMask  |-> [i \in 1 .. 2 |-> 0],
      contraStockLegShortSale   |-> [i \in 1 .. 1 |-> 0],
      contraStockLegMpid        |-> [i \in 1 .. 4 |-> 0],
      contraStockCapacity       |-> [i \in 1 .. 1 |-> 0],
      flexLegPrices             |-> << >> ]

(* New Cross Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewCrossOrderMessage ==
    { ZeroNewCrossOrderMessage }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.auctionAllocPct = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.iso = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.effectiveTime = one] : one \in Sample(8) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.disclosureMask = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.auctionDuration = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryClOrdId = one] : one \in Sample(16) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryCmta = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryClearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryOccAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryCustAcct = one] : one \in Sample(10) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryQuantity = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryPositionEffectMask = one] : one \in Sample(2) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryStockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryStockLegMpid = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.primaryStockCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraClOrdId = one] : one \in Sample(16) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraCmta = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraClearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraOccAccount = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraCustAcct = one] : one \in Sample(10) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraOrderType = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraQuantity = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraPositionEffectMask = one] : one \in Sample(2) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraStockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraStockLegMpid = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.contraStockCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossOrderMessage EXCEPT !.flexLegPrices = one] : one \in SampleLists(OneFlexLegPrices2) }

(***************************************************************************)
(* Complex Instrument Legs: 8 bytes                                        *)
(***************************************************************************)

ComplexInstrumentLegs ==
    [ legType         : Sample(1),
      legInstrumentId : Sample(4),
      legSide         : Sample(1),
      legRatio        : Sample(2) ]

EncodeComplexInstrumentLegs(message) ==
    message.legType
        \o message.legInstrumentId
        \o message.legSide
        \o message.legRatio

DecodeComplexInstrumentLegs(bytes) ==
    LET legType == ReadBytes(bytes, 1) IN IF ~legType.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(legType.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legInstrumentId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 2) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ legType         |-> legType.value,
         legInstrumentId |-> legInstrumentId.value,
         legSide         |-> legSide.value,
         legRatio        |-> legRatio.value ], legRatio.rest)

ZeroComplexInstrumentLegs ==
    [ legType         |-> [i \in 1 .. 1 |-> 0],
      legInstrumentId |-> [i \in 1 .. 4 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      legRatio        |-> [i \in 1 .. 2 |-> 0] ]

(* Complex Instrument Legs at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentLegs ==
    { ZeroComplexInstrumentLegs }
        \cup { [ZeroComplexInstrumentLegs EXCEPT !.legType = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentLegs EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentLegs EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentLegs EXCEPT !.legRatio = one] : one \in Sample(2) }

(* A run of Complex Instrument Legs, written one after another *)
RECURSIVE EncodeComplexInstrumentLegsList(_)
EncodeComplexInstrumentLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexInstrumentLegs(Head(messages)) \o EncodeComplexInstrumentLegsList(Tail(messages))

(* As many Complex Instrument Legs as the field that counts them says *)
RECURSIVE ReadComplexInstrumentLegsList(_, _)
ReadComplexInstrumentLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexInstrumentLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexInstrumentLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Instrument Legs of each kind, for the lists that carry them *)
OneComplexInstrumentLegs == { ZeroComplexInstrumentLegs }

(***************************************************************************)
(* Add Complex Instrument Message                                          *)
(***************************************************************************)

AddComplexInstrumentMessage ==
    [ firmId                : Sample(4),
      clRequestId           : Sample(16),
      productId             : Sample(2),
      productName           : Sample(13),
      complexInstrumentLegs : SampleLists(OneComplexInstrumentLegs) ]

EncodeAddComplexInstrumentMessage(message) ==
    message.firmId
        \o message.clRequestId
        \o message.productId
        \o message.productName
        \o EncodeUIntBE(Len(message.complexInstrumentLegs), 1)
        \o EncodeComplexInstrumentLegsList(message.complexInstrumentLegs)

DecodeAddComplexInstrumentMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(firmId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    LET productId == ReadBytes(clRequestId.rest, 2) IN IF ~productId.ok THEN Fail ELSE
    LET productName == ReadBytes(productId.rest, 13) IN IF ~productName.ok THEN Fail ELSE
    LET numLegs == ReadUIntBE(productName.rest, 1) IN IF ~numLegs.ok THEN Fail ELSE
    LET complexInstrumentLegs == ReadComplexInstrumentLegsList(numLegs.rest, numLegs.value) IN IF ~complexInstrumentLegs.ok THEN Fail ELSE
    Ok([ firmId                |-> firmId.value,
         clRequestId           |-> clRequestId.value,
         productId             |-> productId.value,
         productName           |-> productName.value,
         complexInstrumentLegs |-> complexInstrumentLegs.value ], complexInstrumentLegs.rest)

ZeroAddComplexInstrumentMessage ==
    [ firmId                |-> [i \in 1 .. 4 |-> 0],
      clRequestId           |-> [i \in 1 .. 16 |-> 0],
      productId             |-> [i \in 1 .. 2 |-> 0],
      productName           |-> [i \in 1 .. 13 |-> 0],
      complexInstrumentLegs |-> << >> ]

(* Add Complex Instrument Message at zero, then each field in turn at the values it is checked at *)
CheckedAddComplexInstrumentMessage ==
    { ZeroAddComplexInstrumentMessage }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.productId = one] : one \in Sample(2) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.productName = one] : one \in Sample(13) }
        \cup { [ZeroAddComplexInstrumentMessage EXCEPT !.complexInstrumentLegs = one] : one \in SampleLists(OneComplexInstrumentLegs) }

(***************************************************************************)
(* Trade Splits: 33 bytes                                                  *)
(***************************************************************************)

TradeSplits ==
    [ allocQty        : Sample(4),
      cmta            : Sample(4),
      clearingAccount : Sample(4),
      occAccount      : Sample(4),
      custAcct        : Sample(10),
      stockLegMpid    : Sample(4),
      capacity        : Sample(1),
      openClose       : Sample(1),
      stockCapacity   : Sample(1) ]

EncodeTradeSplits(message) ==
    message.allocQty
        \o message.cmta
        \o message.clearingAccount
        \o message.occAccount
        \o message.custAcct
        \o message.stockLegMpid
        \o message.capacity
        \o message.openClose
        \o message.stockCapacity

DecodeTradeSplits(bytes) ==
    LET allocQty == ReadBytes(bytes, 4) IN IF ~allocQty.ok THEN Fail ELSE
    LET cmta == ReadBytes(allocQty.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(cmta.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET occAccount == ReadBytes(clearingAccount.rest, 4) IN IF ~occAccount.ok THEN Fail ELSE
    LET custAcct == ReadBytes(occAccount.rest, 10) IN IF ~custAcct.ok THEN Fail ELSE
    LET stockLegMpid == ReadBytes(custAcct.rest, 4) IN IF ~stockLegMpid.ok THEN Fail ELSE
    LET capacity == ReadBytes(stockLegMpid.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET openClose == ReadBytes(capacity.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET stockCapacity == ReadBytes(openClose.rest, 1) IN IF ~stockCapacity.ok THEN Fail ELSE
    Ok([ allocQty        |-> allocQty.value,
         cmta            |-> cmta.value,
         clearingAccount |-> clearingAccount.value,
         occAccount      |-> occAccount.value,
         custAcct        |-> custAcct.value,
         stockLegMpid    |-> stockLegMpid.value,
         capacity        |-> capacity.value,
         openClose       |-> openClose.value,
         stockCapacity   |-> stockCapacity.value ], stockCapacity.rest)

ZeroTradeSplits ==
    [ allocQty        |-> [i \in 1 .. 4 |-> 0],
      cmta            |-> [i \in 1 .. 4 |-> 0],
      clearingAccount |-> [i \in 1 .. 4 |-> 0],
      occAccount      |-> [i \in 1 .. 4 |-> 0],
      custAcct        |-> [i \in 1 .. 10 |-> 0],
      stockLegMpid    |-> [i \in 1 .. 4 |-> 0],
      capacity        |-> [i \in 1 .. 1 |-> 0],
      openClose       |-> [i \in 1 .. 1 |-> 0],
      stockCapacity   |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Splits at zero, then each field in turn at the values it is checked at *)
CheckedTradeSplits ==
    { ZeroTradeSplits }
        \cup { [ZeroTradeSplits EXCEPT !.allocQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeSplits EXCEPT !.cmta = one] : one \in Sample(4) }
        \cup { [ZeroTradeSplits EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroTradeSplits EXCEPT !.occAccount = one] : one \in Sample(4) }
        \cup { [ZeroTradeSplits EXCEPT !.custAcct = one] : one \in Sample(10) }
        \cup { [ZeroTradeSplits EXCEPT !.stockLegMpid = one] : one \in Sample(4) }
        \cup { [ZeroTradeSplits EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeSplits EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeSplits EXCEPT !.stockCapacity = one] : one \in Sample(1) }

(* A run of Trade Splits, written one after another *)
RECURSIVE EncodeTradeSplitsList(_)
EncodeTradeSplitsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTradeSplits(Head(messages)) \o EncodeTradeSplitsList(Tail(messages))

(* As many Trade Splits as the field that counts them says *)
RECURSIVE ReadTradeSplitsList(_, _)
ReadTradeSplitsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTradeSplits(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTradeSplitsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trade Splits of each kind, for the lists that carry them *)
OneTradeSplits == { ZeroTradeSplits }

(***************************************************************************)
(* Modify Trade Message                                                    *)
(***************************************************************************)

ModifyTradeMessage ==
    [ firmId       : Sample(4),
      instrumentId : Sample(4),
      clRequestId  : Sample(16),
      clOrdId      : Sample(16),
      crossId      : Sample(4),
      matchId      : Sample(4),
      side         : Sample(1),
      quantity     : Sample(4),
      tradeSplits  : SampleLists(OneTradeSplits) ]

EncodeModifyTradeMessage(message) ==
    message.firmId
        \o message.instrumentId
        \o message.clRequestId
        \o message.clOrdId
        \o message.crossId
        \o message.matchId
        \o message.side
        \o message.quantity
        \o EncodeUIntBE(Len(message.tradeSplits), 2)
        \o EncodeTradeSplitsList(message.tradeSplits)

DecodeModifyTradeMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(instrumentId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(clRequestId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET crossId == ReadBytes(clOrdId.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    LET side == ReadBytes(matchId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET numSplits == ReadUIntBE(quantity.rest, 2) IN IF ~numSplits.ok THEN Fail ELSE
    LET tradeSplits == ReadTradeSplitsList(numSplits.rest, numSplits.value) IN IF ~tradeSplits.ok THEN Fail ELSE
    Ok([ firmId       |-> firmId.value,
         instrumentId |-> instrumentId.value,
         clRequestId  |-> clRequestId.value,
         clOrdId      |-> clOrdId.value,
         crossId      |-> crossId.value,
         matchId      |-> matchId.value,
         side         |-> side.value,
         quantity     |-> quantity.value,
         tradeSplits  |-> tradeSplits.value ], tradeSplits.rest)

ZeroModifyTradeMessage ==
    [ firmId       |-> [i \in 1 .. 4 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      clRequestId  |-> [i \in 1 .. 16 |-> 0],
      clOrdId      |-> [i \in 1 .. 16 |-> 0],
      crossId      |-> [i \in 1 .. 4 |-> 0],
      matchId      |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      quantity     |-> [i \in 1 .. 4 |-> 0],
      tradeSplits  |-> << >> ]

(* Modify Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyTradeMessage ==
    { ZeroModifyTradeMessage }
        \cup { [ZeroModifyTradeMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTradeMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }
        \cup { [ZeroModifyTradeMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroModifyTradeMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTradeMessage EXCEPT !.matchId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroModifyTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroModifyTradeMessage EXCEPT !.tradeSplits = one] : one \in SampleLists(OneTradeSplits) }

(***************************************************************************)
(* Member Kill Switch Request Message: 25 bytes                            *)
(***************************************************************************)

MemberKillSwitchRequestMessage ==
    [ firmId       : Sample(4),
      clRequestId  : Sample(16),
      targetFirmId : Sample(4),
      killAction   : Sample(1) ]

EncodeMemberKillSwitchRequestMessage(message) ==
    message.firmId
        \o message.clRequestId
        \o message.targetFirmId
        \o message.killAction

DecodeMemberKillSwitchRequestMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(firmId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    LET targetFirmId == ReadBytes(clRequestId.rest, 4) IN IF ~targetFirmId.ok THEN Fail ELSE
    LET killAction == ReadBytes(targetFirmId.rest, 1) IN IF ~killAction.ok THEN Fail ELSE
    Ok([ firmId       |-> firmId.value,
         clRequestId  |-> clRequestId.value,
         targetFirmId |-> targetFirmId.value,
         killAction   |-> killAction.value ], killAction.rest)

ZeroMemberKillSwitchRequestMessage ==
    [ firmId       |-> [i \in 1 .. 4 |-> 0],
      clRequestId  |-> [i \in 1 .. 16 |-> 0],
      targetFirmId |-> [i \in 1 .. 4 |-> 0],
      killAction   |-> [i \in 1 .. 1 |-> 0] ]

(* Member Kill Switch Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMemberKillSwitchRequestMessage ==
    { ZeroMemberKillSwitchRequestMessage }
        \cup { [ZeroMemberKillSwitchRequestMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroMemberKillSwitchRequestMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }
        \cup { [ZeroMemberKillSwitchRequestMessage EXCEPT !.targetFirmId = one] : one \in Sample(4) }
        \cup { [ZeroMemberKillSwitchRequestMessage EXCEPT !.killAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Subscription Request Message: 36 bytes                                  *)
(***************************************************************************)

SubscriptionRequestMessage ==
    [ firmId       : Sample(4),
      clRequestId  : Sample(16),
      subscription : Sample(16) ]

EncodeSubscriptionRequestMessage(message) ==
    message.firmId
        \o message.clRequestId
        \o message.subscription

DecodeSubscriptionRequestMessage(bytes) ==
    LET firmId == ReadBytes(bytes, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(firmId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    LET subscription == ReadBytes(clRequestId.rest, 16) IN IF ~subscription.ok THEN Fail ELSE
    Ok([ firmId       |-> firmId.value,
         clRequestId  |-> clRequestId.value,
         subscription |-> subscription.value ], subscription.rest)

ZeroSubscriptionRequestMessage ==
    [ firmId       |-> [i \in 1 .. 4 |-> 0],
      clRequestId  |-> [i \in 1 .. 16 |-> 0],
      subscription |-> [i \in 1 .. 16 |-> 0] ]

(* Subscription Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSubscriptionRequestMessage ==
    { ZeroSubscriptionRequestMessage }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.subscription = one] : one \in Sample(16) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

NewOrderLongFormMessageCode == 65  \* "A"
NewOrderShortFormMessageCode == 66  \* "B"
ReplaceOrderMessageCode == 82  \* "R"
CancelOrderMessageCode == 67  \* "C"
MassCancelMessageCode == 85  \* "U"
NewCrossOrderMessageCode == 88  \* "X"
AddComplexInstrumentMessageCode == 83  \* "S"
ModifyTradeMessageCode == 77  \* "M"
MemberKillSwitchRequestMessageCode == 75  \* "K"
SubscriptionRequestMessageCode == 70  \* "F"

UnsequencedMessage ==
    [ tag : {NewOrderLongFormMessageCode}, body : NewOrderLongFormMessage ]
        \cup [ tag : {NewOrderShortFormMessageCode}, body : NewOrderShortFormMessage ]
        \cup [ tag : {ReplaceOrderMessageCode}, body : ReplaceOrderMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {MassCancelMessageCode}, body : MassCancelMessage ]
        \cup [ tag : {NewCrossOrderMessageCode}, body : NewCrossOrderMessage ]
        \cup [ tag : {AddComplexInstrumentMessageCode}, body : AddComplexInstrumentMessage ]
        \cup [ tag : {ModifyTradeMessageCode}, body : ModifyTradeMessage ]
        \cup [ tag : {MemberKillSwitchRequestMessageCode}, body : MemberKillSwitchRequestMessage ]
        \cup [ tag : {SubscriptionRequestMessageCode}, body : SubscriptionRequestMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = NewOrderLongFormMessageCode -> EncodeNewOrderLongFormMessage(message.body)
      [] message.tag = NewOrderShortFormMessageCode -> EncodeNewOrderShortFormMessage(message.body)
      [] message.tag = ReplaceOrderMessageCode -> EncodeReplaceOrderMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = MassCancelMessageCode -> EncodeMassCancelMessage(message.body)
      [] message.tag = NewCrossOrderMessageCode -> EncodeNewCrossOrderMessage(message.body)
      [] message.tag = AddComplexInstrumentMessageCode -> EncodeAddComplexInstrumentMessage(message.body)
      [] message.tag = ModifyTradeMessageCode -> EncodeModifyTradeMessage(message.body)
      [] message.tag = MemberKillSwitchRequestMessageCode -> EncodeMemberKillSwitchRequestMessage(message.body)
      [] message.tag = SubscriptionRequestMessageCode -> EncodeSubscriptionRequestMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderLongFormMessageCode -> DecodeNewOrderLongFormMessage(bytes)
              [] tag = NewOrderShortFormMessageCode -> DecodeNewOrderShortFormMessage(bytes)
              [] tag = ReplaceOrderMessageCode -> DecodeReplaceOrderMessage(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] tag = MassCancelMessageCode -> DecodeMassCancelMessage(bytes)
              [] tag = NewCrossOrderMessageCode -> DecodeNewCrossOrderMessage(bytes)
              [] tag = AddComplexInstrumentMessageCode -> DecodeAddComplexInstrumentMessage(bytes)
              [] tag = ModifyTradeMessageCode -> DecodeModifyTradeMessage(bytes)
              [] tag = MemberKillSwitchRequestMessageCode -> DecodeMemberKillSwitchRequestMessage(bytes)
              [] tag = SubscriptionRequestMessageCode -> DecodeSubscriptionRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> NewOrderLongFormMessageCode, body |-> ZeroNewOrderLongFormMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> NewOrderLongFormMessageCode, body |-> one] : one \in CheckedNewOrderLongFormMessage }
        \cup { [tag |-> NewOrderShortFormMessageCode, body |-> one] : one \in CheckedNewOrderShortFormMessage }
        \cup { [tag |-> ReplaceOrderMessageCode, body |-> one] : one \in CheckedReplaceOrderMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> MassCancelMessageCode, body |-> one] : one \in CheckedMassCancelMessage }
        \cup { [tag |-> NewCrossOrderMessageCode, body |-> one] : one \in CheckedNewCrossOrderMessage }
        \cup { [tag |-> AddComplexInstrumentMessageCode, body |-> one] : one \in CheckedAddComplexInstrumentMessage }
        \cup { [tag |-> ModifyTradeMessageCode, body |-> one] : one \in CheckedModifyTradeMessage }
        \cup { [tag |-> MemberKillSwitchRequestMessageCode, body |-> one] : one \in CheckedMemberKillSwitchRequestMessage }
        \cup { [tag |-> SubscriptionRequestMessageCode, body |-> one] : one \in CheckedSubscriptionRequestMessage }

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
ClientHeartbeatPacketCode == 82  \* "R"
LogoutRequestPacketCode == 79  \* "O"

ClientPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {ClientHeartbeatPacketCode}, body : {0} ]
        \cup [ tag : {LogoutRequestPacketCode}, body : {0} ]

EncodeClientPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = ClientHeartbeatPacketCode -> << >>
      [] message.tag = LogoutRequestPacketCode -> << >>

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = ClientHeartbeatPacketCode -> Ok(0, bytes)
              [] tag = LogoutRequestPacketCode -> Ok(0, bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> ClientHeartbeatPacketCode, body |-> 0] }
        \cup { [tag |-> LogoutRequestPacketCode, body |-> 0] }

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
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> ClientHeartbeatPacketCode, body |-> 0]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LogoutRequestPacketCode, body |-> 0]] }

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

(* Every Flex Leg Prices decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexLegPrices ==
    \A message \in CheckedFlexLegPrices :
        LET read == DecodeFlexLegPrices(EncodeFlexLegPrices(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderLongFormMessage ==
    \A message \in CheckedNewOrderLongFormMessage :
        LET read == DecodeNewOrderLongFormMessage(EncodeNewOrderLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderShortFormMessage ==
    \A message \in CheckedNewOrderShortFormMessage :
        LET read == DecodeNewOrderShortFormMessage(EncodeNewOrderShortFormMessage(message))
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

(* Every Mass Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelMessage ==
    \A message \in CheckedMassCancelMessage :
        LET read == DecodeMassCancelMessage(EncodeMassCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Leg Prices decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexLegPrices2 ==
    \A message \in CheckedFlexLegPrices2 :
        LET read == DecodeFlexLegPrices2(EncodeFlexLegPrices2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Cross Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewCrossOrderMessage ==
    \A message \in CheckedNewCrossOrderMessage :
        LET read == DecodeNewCrossOrderMessage(EncodeNewCrossOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentLegs ==
    \A message \in CheckedComplexInstrumentLegs :
        LET read == DecodeComplexInstrumentLegs(EncodeComplexInstrumentLegs(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Complex Instrument Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddComplexInstrumentMessage ==
    \A message \in CheckedAddComplexInstrumentMessage :
        LET read == DecodeAddComplexInstrumentMessage(EncodeAddComplexInstrumentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Splits decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSplits ==
    \A message \in CheckedTradeSplits :
        LET read == DecodeTradeSplits(EncodeTradeSplits(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyTradeMessage ==
    \A message \in CheckedModifyTradeMessage :
        LET read == DecodeModifyTradeMessage(EncodeModifyTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Member Kill Switch Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMemberKillSwitchRequestMessage ==
    \A message \in CheckedMemberKillSwitchRequestMessage :
        LET read == DecodeMemberKillSwitchRequestMessage(EncodeMemberKillSwitchRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscription Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscriptionRequestMessage ==
    \A message \in CheckedSubscriptionRequestMessage :
        LET read == DecodeSubscriptionRequestMessage(EncodeSubscriptionRequestMessage(message))
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
