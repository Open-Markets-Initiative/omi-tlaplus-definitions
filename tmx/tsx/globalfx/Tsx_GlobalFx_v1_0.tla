------------------------- MODULE Tsx_GlobalFx_v1_0 -------------------------
(***************************************************************************)
(* TMX Group Global Fx Feed v1.0                                           *)
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
(* Bid Price: 5 bytes                                                      *)
(***************************************************************************)

BidPrice ==
    [ bidPriceMantissa : Sample(4),
      bidPriceExponent : Sample(1) ]

EncodeBidPrice(message) ==
    message.bidPriceMantissa
        \o message.bidPriceExponent

DecodeBidPrice(bytes) ==
    LET bidPriceMantissa == ReadBytes(bytes, 4) IN IF ~bidPriceMantissa.ok THEN Fail ELSE
    LET bidPriceExponent == ReadBytes(bidPriceMantissa.rest, 1) IN IF ~bidPriceExponent.ok THEN Fail ELSE
    Ok([ bidPriceMantissa |-> bidPriceMantissa.value,
         bidPriceExponent |-> bidPriceExponent.value ], bidPriceExponent.rest)

ZeroBidPrice ==
    [ bidPriceMantissa |-> [i \in 1 .. 4 |-> 0],
      bidPriceExponent |-> [i \in 1 .. 1 |-> 0] ]

(* Bid Price at zero, then each field in turn at the values it is checked at *)
CheckedBidPrice ==
    { ZeroBidPrice }
        \cup { [ZeroBidPrice EXCEPT !.bidPriceMantissa = one] : one \in Sample(4) }
        \cup { [ZeroBidPrice EXCEPT !.bidPriceExponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Offer Price: 5 bytes                                                    *)
(***************************************************************************)

OfferPrice ==
    [ offerPriceMantissa : Sample(4),
      offerPriceExponent : Sample(1) ]

EncodeOfferPrice(message) ==
    message.offerPriceMantissa
        \o message.offerPriceExponent

DecodeOfferPrice(bytes) ==
    LET offerPriceMantissa == ReadBytes(bytes, 4) IN IF ~offerPriceMantissa.ok THEN Fail ELSE
    LET offerPriceExponent == ReadBytes(offerPriceMantissa.rest, 1) IN IF ~offerPriceExponent.ok THEN Fail ELSE
    Ok([ offerPriceMantissa |-> offerPriceMantissa.value,
         offerPriceExponent |-> offerPriceExponent.value ], offerPriceExponent.rest)

ZeroOfferPrice ==
    [ offerPriceMantissa |-> [i \in 1 .. 4 |-> 0],
      offerPriceExponent |-> [i \in 1 .. 1 |-> 0] ]

(* Offer Price at zero, then each field in turn at the values it is checked at *)
CheckedOfferPrice ==
    { ZeroOfferPrice }
        \cup { [ZeroOfferPrice EXCEPT !.offerPriceMantissa = one] : one \in Sample(4) }
        \cup { [ZeroOfferPrice EXCEPT !.offerPriceExponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Size Tier: 16 bytes                                                     *)
(***************************************************************************)

SizeTier ==
    [ tierStatus : Sample(1),
      tierSize   : Sample(4),
      priceTerms : Sample(1),
      bidPrice   : BidPrice,
      offerPrice : OfferPrice ]

EncodeSizeTier(message) ==
    message.tierStatus
        \o message.tierSize
        \o message.priceTerms
        \o EncodeBidPrice(message.bidPrice)
        \o EncodeOfferPrice(message.offerPrice)

DecodeSizeTier(bytes) ==
    LET tierStatus == ReadBytes(bytes, 1) IN IF ~tierStatus.ok THEN Fail ELSE
    LET tierSize == ReadBytes(tierStatus.rest, 4) IN IF ~tierSize.ok THEN Fail ELSE
    LET priceTerms == ReadBytes(tierSize.rest, 1) IN IF ~priceTerms.ok THEN Fail ELSE
    LET bidPrice == DecodeBidPrice(priceTerms.rest) IN IF ~bidPrice.ok THEN Fail ELSE
    LET offerPrice == DecodeOfferPrice(bidPrice.rest) IN IF ~offerPrice.ok THEN Fail ELSE
    Ok([ tierStatus |-> tierStatus.value,
         tierSize   |-> tierSize.value,
         priceTerms |-> priceTerms.value,
         bidPrice   |-> bidPrice.value,
         offerPrice |-> offerPrice.value ], offerPrice.rest)

ZeroSizeTier ==
    [ tierStatus |-> [i \in 1 .. 1 |-> 0],
      tierSize   |-> [i \in 1 .. 4 |-> 0],
      priceTerms |-> [i \in 1 .. 1 |-> 0],
      bidPrice   |-> ZeroBidPrice,
      offerPrice |-> ZeroOfferPrice ]

(* Size Tier at zero, then each field in turn at the values it is checked at *)
CheckedSizeTier ==
    { ZeroSizeTier }
        \cup { [ZeroSizeTier EXCEPT !.tierStatus = one] : one \in Sample(1) }
        \cup { [ZeroSizeTier EXCEPT !.tierSize = one] : one \in Sample(4) }
        \cup { [ZeroSizeTier EXCEPT !.priceTerms = one] : one \in Sample(1) }
        \cup { [ZeroSizeTier EXCEPT !.bidPrice = one] : one \in CheckedBidPrice }
        \cup { [ZeroSizeTier EXCEPT !.offerPrice = one] : one \in CheckedOfferPrice }

(* A run of Size Tier, written one after another *)
RECURSIVE EncodeSizeTierList(_)
EncodeSizeTierList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSizeTier(Head(messages)) \o EncodeSizeTierList(Tail(messages))

(* As many Size Tier as the field that counts them says *)
RECURSIVE ReadSizeTierList(_, _)
ReadSizeTierList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSizeTier(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSizeTierList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Size Tier of each kind, for the lists that carry them *)
OneSizeTier == { ZeroSizeTier }

(***************************************************************************)
(* Reference Price Fx Spot                                                 *)
(***************************************************************************)

ReferencePriceFxSpot ==
    [ unused1         : Sample(1),
      currency1       : Sample(3),
      currency2       : Sample(3),
      timestamp       : Sample(8),
      streamId        : Sample(8),
      sequenceNumber  : Sample(4),
      validForSeconds : Sample(2),
      unused2         : Sample(1),
      sizeTier        : SampleLists(OneSizeTier) ]

EncodeReferencePriceFxSpot(message) ==
    message.unused1
        \o message.currency1
        \o message.currency2
        \o message.timestamp
        \o message.streamId
        \o message.sequenceNumber
        \o message.validForSeconds
        \o message.unused2
        \o EncodeUIntBE(Len(message.sizeTier), 1)
        \o EncodeSizeTierList(message.sizeTier)

DecodeReferencePriceFxSpot(bytes) ==
    LET unused1 == ReadBytes(bytes, 1) IN IF ~unused1.ok THEN Fail ELSE
    LET currency1 == ReadBytes(unused1.rest, 3) IN IF ~currency1.ok THEN Fail ELSE
    LET currency2 == ReadBytes(currency1.rest, 3) IN IF ~currency2.ok THEN Fail ELSE
    LET timestamp == ReadBytes(currency2.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET streamId == ReadBytes(timestamp.rest, 8) IN IF ~streamId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(streamId.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET validForSeconds == ReadBytes(sequenceNumber.rest, 2) IN IF ~validForSeconds.ok THEN Fail ELSE
    LET unused2 == ReadBytes(validForSeconds.rest, 1) IN IF ~unused2.ok THEN Fail ELSE
    LET numberOfTiers == ReadUIntBE(unused2.rest, 1) IN IF ~numberOfTiers.ok THEN Fail ELSE
    LET sizeTier == ReadSizeTierList(numberOfTiers.rest, numberOfTiers.value) IN IF ~sizeTier.ok THEN Fail ELSE
    Ok([ unused1         |-> unused1.value,
         currency1       |-> currency1.value,
         currency2       |-> currency2.value,
         timestamp       |-> timestamp.value,
         streamId        |-> streamId.value,
         sequenceNumber  |-> sequenceNumber.value,
         validForSeconds |-> validForSeconds.value,
         unused2         |-> unused2.value,
         sizeTier        |-> sizeTier.value ], sizeTier.rest)

ZeroReferencePriceFxSpot ==
    [ unused1         |-> [i \in 1 .. 1 |-> 0],
      currency1       |-> [i \in 1 .. 3 |-> 0],
      currency2       |-> [i \in 1 .. 3 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      streamId        |-> [i \in 1 .. 8 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      validForSeconds |-> [i \in 1 .. 2 |-> 0],
      unused2         |-> [i \in 1 .. 1 |-> 0],
      sizeTier        |-> << >> ]

(* Reference Price Fx Spot at zero, then each field in turn at the values it is checked at *)
CheckedReferencePriceFxSpot ==
    { ZeroReferencePriceFxSpot }
        \cup { [ZeroReferencePriceFxSpot EXCEPT !.unused1 = one] : one \in Sample(1) }
        \cup { [ZeroReferencePriceFxSpot EXCEPT !.currency1 = one] : one \in Sample(3) }
        \cup { [ZeroReferencePriceFxSpot EXCEPT !.currency2 = one] : one \in Sample(3) }
        \cup { [ZeroReferencePriceFxSpot EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceFxSpot EXCEPT !.streamId = one] : one \in Sample(8) }
        \cup { [ZeroReferencePriceFxSpot EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroReferencePriceFxSpot EXCEPT !.validForSeconds = one] : one \in Sample(2) }
        \cup { [ZeroReferencePriceFxSpot EXCEPT !.unused2 = one] : one \in Sample(1) }
        \cup { [ZeroReferencePriceFxSpot EXCEPT !.sizeTier = one] : one \in SampleLists(OneSizeTier) }

(***************************************************************************)
(* Datagram Body, selected by Msg Type                                     *)
(***************************************************************************)

ReferencePriceFxSpotCode == 35  \* "#"

DatagramBody ==
    [ tag : {ReferencePriceFxSpotCode}, body : ReferencePriceFxSpot ]

EncodeDatagramBody(message) ==
    CASE message.tag = ReferencePriceFxSpotCode -> EncodeReferencePriceFxSpot(message.body)

DecodeDatagramBody(tag, bytes) ==
    LET read ==
            CASE tag = ReferencePriceFxSpotCode -> DecodeReferencePriceFxSpot(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroDatagramBody == [tag |-> ReferencePriceFxSpotCode, body |-> ZeroReferencePriceFxSpot]

(* Each Datagram Body in turn, at the values the message it names is checked at *)
CheckedDatagramBody ==
    { [tag |-> ReferencePriceFxSpotCode, body |-> one] : one \in CheckedReferencePriceFxSpot }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ datagramBody : DatagramBody ]

EncodePacket(message) ==
    EncodeUIntBE(message.datagramBody.tag, 1)
        \o EncodeDatagramBody(message.datagramBody)

DecodePacket(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET datagramBody == DecodeDatagramBody(msgType.value, msgType.rest) IN IF ~datagramBody.ok THEN Fail ELSE
    Ok([ datagramBody |-> datagramBody.value ], datagramBody.rest)

ZeroPacket ==
    [ datagramBody |-> ZeroDatagramBody ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.datagramBody = one] : one \in CheckedDatagramBody }

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

(* Every Bid Price decodes back to what was encoded, and leaves nothing over *)
RoundTripBidPrice ==
    \A message \in CheckedBidPrice :
        LET read == DecodeBidPrice(EncodeBidPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Offer Price decodes back to what was encoded, and leaves nothing over *)
RoundTripOfferPrice ==
    \A message \in CheckedOfferPrice :
        LET read == DecodeOfferPrice(EncodeOfferPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Size Tier decodes back to what was encoded, and leaves nothing over *)
RoundTripSizeTier ==
    \A message \in CheckedSizeTier :
        LET read == DecodeSizeTier(EncodeSizeTier(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reference Price Fx Spot decodes back to what was encoded, and leaves nothing over *)
RoundTripReferencePriceFxSpot ==
    \A message \in CheckedReferencePriceFxSpot :
        LET read == DecodeReferencePriceFxSpot(EncodeReferencePriceFxSpot(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Datagram Body is selected by the Msg Type it is written under *)
SelectsDatagramBody ==
    \A message \in CheckedDatagramBody :
        LET read == DecodeDatagramBody(message.tag, EncodeDatagramBody(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
