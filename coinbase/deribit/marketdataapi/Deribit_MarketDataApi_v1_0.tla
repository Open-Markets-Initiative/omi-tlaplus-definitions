-------------------- MODULE Deribit_MarketDataApi_v1_0 ---------------------
(***************************************************************************)
(* Coinbase Market Data Api v1.0                                           *)
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
(* Note: Packet Type is a bit field set, checked as its 2 bytes rather     *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: a Message Count of 0 marks Empty Packet and carries no Md         *)
(* Message.                                                                *)
(*                                                                         *)
(* Note: Message Flags is a bit field set, checked as its 2 bytes rather   *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Flags is a bit field set, checked as its 1 byte rather than bit   *)
(* by bit.                                                                 *)
(*                                                                         *)
(* Note: Taker Flags is a bit field set, checked as its 4 bytes rather     *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Maker Flags is a bit field set, checked as its 4 bytes rather     *)
(* than bit by bit.                                                        *)
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
(* Instrument Definition Message large Tick Sizes Group: 16 bytes          *)
(***************************************************************************)

InstrumentDefinitionMessageLargeTickSizesGroup ==
    [ largeTickSize  : Sample(8),
      thresholdPrice : Sample(8) ]

EncodeInstrumentDefinitionMessageLargeTickSizesGroup(message) ==
    message.largeTickSize
        \o message.thresholdPrice

DecodeInstrumentDefinitionMessageLargeTickSizesGroup(bytes) ==
    LET largeTickSize == ReadBytes(bytes, 8) IN IF ~largeTickSize.ok THEN Fail ELSE
    LET thresholdPrice == ReadBytes(largeTickSize.rest, 8) IN IF ~thresholdPrice.ok THEN Fail ELSE
    Ok([ largeTickSize  |-> largeTickSize.value,
         thresholdPrice |-> thresholdPrice.value ], thresholdPrice.rest)

ZeroInstrumentDefinitionMessageLargeTickSizesGroup ==
    [ largeTickSize  |-> [i \in 1 .. 8 |-> 0],
      thresholdPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Definition Message large Tick Sizes Group at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDefinitionMessageLargeTickSizesGroup ==
    { ZeroInstrumentDefinitionMessageLargeTickSizesGroup }
        \cup { [ZeroInstrumentDefinitionMessageLargeTickSizesGroup EXCEPT !.largeTickSize = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessageLargeTickSizesGroup EXCEPT !.thresholdPrice = one] : one \in Sample(8) }

(* A run of Instrument Definition Message large Tick Sizes Group, written one after another *)
RECURSIVE EncodeInstrumentDefinitionMessageLargeTickSizesGroupList(_)
EncodeInstrumentDefinitionMessageLargeTickSizesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentDefinitionMessageLargeTickSizesGroup(Head(messages)) \o EncodeInstrumentDefinitionMessageLargeTickSizesGroupList(Tail(messages))

(* As many Instrument Definition Message large Tick Sizes Group as the field that counts them says *)
RECURSIVE ReadInstrumentDefinitionMessageLargeTickSizesGroupList(_, _)
ReadInstrumentDefinitionMessageLargeTickSizesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentDefinitionMessageLargeTickSizesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentDefinitionMessageLargeTickSizesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Definition Message large Tick Sizes Group of each kind, for the lists that carry them *)
OneInstrumentDefinitionMessageLargeTickSizesGroup == { ZeroInstrumentDefinitionMessageLargeTickSizesGroup }

(***************************************************************************)
(* Instrument Definition Message large Tick Sizes Groups                   *)
(***************************************************************************)

InstrumentDefinitionMessageLargeTickSizesGroups ==
    [ blockLength                                    : Sample(2),
      instrumentDefinitionMessageLargeTickSizesGroup : SampleLists(OneInstrumentDefinitionMessageLargeTickSizesGroup) ]

EncodeInstrumentDefinitionMessageLargeTickSizesGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.instrumentDefinitionMessageLargeTickSizesGroup), 2)
        \o EncodeInstrumentDefinitionMessageLargeTickSizesGroupList(message.instrumentDefinitionMessageLargeTickSizesGroup)

DecodeInstrumentDefinitionMessageLargeTickSizesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instrumentDefinitionMessageLargeTickSizesGroup == ReadInstrumentDefinitionMessageLargeTickSizesGroupList(numInGroup.rest, numInGroup.value) IN IF ~instrumentDefinitionMessageLargeTickSizesGroup.ok THEN Fail ELSE
    Ok([ blockLength                                    |-> blockLength.value,
         instrumentDefinitionMessageLargeTickSizesGroup |-> instrumentDefinitionMessageLargeTickSizesGroup.value ], instrumentDefinitionMessageLargeTickSizesGroup.rest)

ZeroInstrumentDefinitionMessageLargeTickSizesGroups ==
    [ blockLength                                    |-> [i \in 1 .. 2 |-> 0],
      instrumentDefinitionMessageLargeTickSizesGroup |-> << >> ]

(* Instrument Definition Message large Tick Sizes Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDefinitionMessageLargeTickSizesGroups ==
    { ZeroInstrumentDefinitionMessageLargeTickSizesGroups }
        \cup { [ZeroInstrumentDefinitionMessageLargeTickSizesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDefinitionMessageLargeTickSizesGroups EXCEPT !.instrumentDefinitionMessageLargeTickSizesGroup = one] : one \in SampleLists(OneInstrumentDefinitionMessageLargeTickSizesGroup) }

(***************************************************************************)
(* Instrument Definition Message legs Group: 9 bytes                       *)
(***************************************************************************)

InstrumentDefinitionMessageLegsGroup ==
    [ legInstrumentId : Sample(8),
      ratio           : Sample(1) ]

EncodeInstrumentDefinitionMessageLegsGroup(message) ==
    message.legInstrumentId
        \o message.ratio

DecodeInstrumentDefinitionMessageLegsGroup(bytes) ==
    LET legInstrumentId == ReadBytes(bytes, 8) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET ratio == ReadBytes(legInstrumentId.rest, 1) IN IF ~ratio.ok THEN Fail ELSE
    Ok([ legInstrumentId |-> legInstrumentId.value,
         ratio           |-> ratio.value ], ratio.rest)

ZeroInstrumentDefinitionMessageLegsGroup ==
    [ legInstrumentId |-> [i \in 1 .. 8 |-> 0],
      ratio           |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Definition Message legs Group at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDefinitionMessageLegsGroup ==
    { ZeroInstrumentDefinitionMessageLegsGroup }
        \cup { [ZeroInstrumentDefinitionMessageLegsGroup EXCEPT !.legInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessageLegsGroup EXCEPT !.ratio = one] : one \in Sample(1) }

(* A run of Instrument Definition Message legs Group, written one after another *)
RECURSIVE EncodeInstrumentDefinitionMessageLegsGroupList(_)
EncodeInstrumentDefinitionMessageLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentDefinitionMessageLegsGroup(Head(messages)) \o EncodeInstrumentDefinitionMessageLegsGroupList(Tail(messages))

(* As many Instrument Definition Message legs Group as the field that counts them says *)
RECURSIVE ReadInstrumentDefinitionMessageLegsGroupList(_, _)
ReadInstrumentDefinitionMessageLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentDefinitionMessageLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentDefinitionMessageLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Definition Message legs Group of each kind, for the lists that carry them *)
OneInstrumentDefinitionMessageLegsGroup == { ZeroInstrumentDefinitionMessageLegsGroup }

(***************************************************************************)
(* Instrument Definition Message legs Groups                               *)
(***************************************************************************)

InstrumentDefinitionMessageLegsGroups ==
    [ blockLength                          : Sample(2),
      instrumentDefinitionMessageLegsGroup : SampleLists(OneInstrumentDefinitionMessageLegsGroup) ]

EncodeInstrumentDefinitionMessageLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntLE(Len(message.instrumentDefinitionMessageLegsGroup), 2)
        \o EncodeInstrumentDefinitionMessageLegsGroupList(message.instrumentDefinitionMessageLegsGroup)

DecodeInstrumentDefinitionMessageLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntLE(blockLength.rest, 2) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instrumentDefinitionMessageLegsGroup == ReadInstrumentDefinitionMessageLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~instrumentDefinitionMessageLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength                          |-> blockLength.value,
         instrumentDefinitionMessageLegsGroup |-> instrumentDefinitionMessageLegsGroup.value ], instrumentDefinitionMessageLegsGroup.rest)

ZeroInstrumentDefinitionMessageLegsGroups ==
    [ blockLength                          |-> [i \in 1 .. 2 |-> 0],
      instrumentDefinitionMessageLegsGroup |-> << >> ]

(* Instrument Definition Message legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDefinitionMessageLegsGroups ==
    { ZeroInstrumentDefinitionMessageLegsGroups }
        \cup { [ZeroInstrumentDefinitionMessageLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDefinitionMessageLegsGroups EXCEPT !.instrumentDefinitionMessageLegsGroup = one] : one \in SampleLists(OneInstrumentDefinitionMessageLegsGroup) }

(***************************************************************************)
(* Instrument Definition Message                                           *)
(***************************************************************************)

InstrumentDefinitionMessage ==
    [ instrumentId                                    : Sample(8),
      name                                            : Sample(128),
      indexId                                         : Sample(8),
      underlying                                      : Sample(64),
      quantityAsset                                   : Sample(8),
      priceAsset                                      : Sample(8),
      expiryTime                                      : Sample(8),
      strikePrice                                     : Sample(8),
      minOrderQuantity                                : Sample(8),
      tickSize                                        : Sample(8),
      quantityExponent                                : Sample(1),
      type                                            : Sample(1),
      flags                                           : Sample(1),
      status                                          : Sample(1),
      instrumentDefinitionMessageLargeTickSizesGroups : InstrumentDefinitionMessageLargeTickSizesGroups,
      instrumentDefinitionMessageLegsGroups           : InstrumentDefinitionMessageLegsGroups ]

EncodeInstrumentDefinitionMessage(message) ==
    message.instrumentId
        \o message.name
        \o message.indexId
        \o message.underlying
        \o message.quantityAsset
        \o message.priceAsset
        \o message.expiryTime
        \o message.strikePrice
        \o message.minOrderQuantity
        \o message.tickSize
        \o message.quantityExponent
        \o message.type
        \o message.flags
        \o message.status
        \o EncodeInstrumentDefinitionMessageLargeTickSizesGroups(message.instrumentDefinitionMessageLargeTickSizesGroups)
        \o EncodeInstrumentDefinitionMessageLegsGroups(message.instrumentDefinitionMessageLegsGroups)

DecodeInstrumentDefinitionMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET name == ReadBytes(instrumentId.rest, 128) IN IF ~name.ok THEN Fail ELSE
    LET indexId == ReadBytes(name.rest, 8) IN IF ~indexId.ok THEN Fail ELSE
    LET underlying == ReadBytes(indexId.rest, 64) IN IF ~underlying.ok THEN Fail ELSE
    LET quantityAsset == ReadBytes(underlying.rest, 8) IN IF ~quantityAsset.ok THEN Fail ELSE
    LET priceAsset == ReadBytes(quantityAsset.rest, 8) IN IF ~priceAsset.ok THEN Fail ELSE
    LET expiryTime == ReadBytes(priceAsset.rest, 8) IN IF ~expiryTime.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryTime.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET minOrderQuantity == ReadBytes(strikePrice.rest, 8) IN IF ~minOrderQuantity.ok THEN Fail ELSE
    LET tickSize == ReadBytes(minOrderQuantity.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET quantityExponent == ReadBytes(tickSize.rest, 1) IN IF ~quantityExponent.ok THEN Fail ELSE
    LET type == ReadBytes(quantityExponent.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET flags == ReadBytes(type.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET status == ReadBytes(flags.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET instrumentDefinitionMessageLargeTickSizesGroups == DecodeInstrumentDefinitionMessageLargeTickSizesGroups(status.rest) IN IF ~instrumentDefinitionMessageLargeTickSizesGroups.ok THEN Fail ELSE
    LET instrumentDefinitionMessageLegsGroups == DecodeInstrumentDefinitionMessageLegsGroups(instrumentDefinitionMessageLargeTickSizesGroups.rest) IN IF ~instrumentDefinitionMessageLegsGroups.ok THEN Fail ELSE
    Ok([ instrumentId                                    |-> instrumentId.value,
         name                                            |-> name.value,
         indexId                                         |-> indexId.value,
         underlying                                      |-> underlying.value,
         quantityAsset                                   |-> quantityAsset.value,
         priceAsset                                      |-> priceAsset.value,
         expiryTime                                      |-> expiryTime.value,
         strikePrice                                     |-> strikePrice.value,
         minOrderQuantity                                |-> minOrderQuantity.value,
         tickSize                                        |-> tickSize.value,
         quantityExponent                                |-> quantityExponent.value,
         type                                            |-> type.value,
         flags                                           |-> flags.value,
         status                                          |-> status.value,
         instrumentDefinitionMessageLargeTickSizesGroups |-> instrumentDefinitionMessageLargeTickSizesGroups.value,
         instrumentDefinitionMessageLegsGroups           |-> instrumentDefinitionMessageLegsGroups.value ], instrumentDefinitionMessageLegsGroups.rest)

ZeroInstrumentDefinitionMessage ==
    [ instrumentId                                    |-> [i \in 1 .. 8 |-> 0],
      name                                            |-> [i \in 1 .. 128 |-> 0],
      indexId                                         |-> [i \in 1 .. 8 |-> 0],
      underlying                                      |-> [i \in 1 .. 64 |-> 0],
      quantityAsset                                   |-> [i \in 1 .. 8 |-> 0],
      priceAsset                                      |-> [i \in 1 .. 8 |-> 0],
      expiryTime                                      |-> [i \in 1 .. 8 |-> 0],
      strikePrice                                     |-> [i \in 1 .. 8 |-> 0],
      minOrderQuantity                                |-> [i \in 1 .. 8 |-> 0],
      tickSize                                        |-> [i \in 1 .. 8 |-> 0],
      quantityExponent                                |-> [i \in 1 .. 1 |-> 0],
      type                                            |-> [i \in 1 .. 1 |-> 0],
      flags                                           |-> [i \in 1 .. 1 |-> 0],
      status                                          |-> [i \in 1 .. 1 |-> 0],
      instrumentDefinitionMessageLargeTickSizesGroups |-> ZeroInstrumentDefinitionMessageLargeTickSizesGroups,
      instrumentDefinitionMessageLegsGroups           |-> ZeroInstrumentDefinitionMessageLegsGroups ]

(* Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDefinitionMessage ==
    { ZeroInstrumentDefinitionMessage }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.name = one] : one \in Sample(128) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.indexId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.underlying = one] : one \in Sample(64) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.quantityAsset = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.priceAsset = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.expiryTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.minOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.quantityExponent = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.instrumentDefinitionMessageLargeTickSizesGroups = one] : one \in CheckedInstrumentDefinitionMessageLargeTickSizesGroups }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.instrumentDefinitionMessageLegsGroups = one] : one \in CheckedInstrumentDefinitionMessageLegsGroups }

(***************************************************************************)
(* Index Definition Message: 136 bytes                                     *)
(***************************************************************************)

IndexDefinitionMessage ==
    [ indexId : Sample(8),
      name    : Sample(128) ]

EncodeIndexDefinitionMessage(message) ==
    message.indexId
        \o message.name

DecodeIndexDefinitionMessage(bytes) ==
    LET indexId == ReadBytes(bytes, 8) IN IF ~indexId.ok THEN Fail ELSE
    LET name == ReadBytes(indexId.rest, 128) IN IF ~name.ok THEN Fail ELSE
    Ok([ indexId |-> indexId.value,
         name    |-> name.value ], name.rest)

ZeroIndexDefinitionMessage ==
    [ indexId |-> [i \in 1 .. 8 |-> 0],
      name    |-> [i \in 1 .. 128 |-> 0] ]

(* Index Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexDefinitionMessage ==
    { ZeroIndexDefinitionMessage }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.indexId = one] : one \in Sample(8) }
        \cup { [ZeroIndexDefinitionMessage EXCEPT !.name = one] : one \in Sample(128) }

(***************************************************************************)
(* Instrument Info Message: 40 bytes                                       *)
(***************************************************************************)

InstrumentInfoMessage ==
    [ instrumentId : Sample(8),
      minSellPrice : Sample(8),
      maxBuyPrice  : Sample(8),
      indexPrice   : Sample(8),
      markPrice    : Sample(8) ]

EncodeInstrumentInfoMessage(message) ==
    message.instrumentId
        \o message.minSellPrice
        \o message.maxBuyPrice
        \o message.indexPrice
        \o message.markPrice

DecodeInstrumentInfoMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET minSellPrice == ReadBytes(instrumentId.rest, 8) IN IF ~minSellPrice.ok THEN Fail ELSE
    LET maxBuyPrice == ReadBytes(minSellPrice.rest, 8) IN IF ~maxBuyPrice.ok THEN Fail ELSE
    LET indexPrice == ReadBytes(maxBuyPrice.rest, 8) IN IF ~indexPrice.ok THEN Fail ELSE
    LET markPrice == ReadBytes(indexPrice.rest, 8) IN IF ~markPrice.ok THEN Fail ELSE
    Ok([ instrumentId |-> instrumentId.value,
         minSellPrice |-> minSellPrice.value,
         maxBuyPrice  |-> maxBuyPrice.value,
         indexPrice   |-> indexPrice.value,
         markPrice    |-> markPrice.value ], markPrice.rest)

ZeroInstrumentInfoMessage ==
    [ instrumentId |-> [i \in 1 .. 8 |-> 0],
      minSellPrice |-> [i \in 1 .. 8 |-> 0],
      maxBuyPrice  |-> [i \in 1 .. 8 |-> 0],
      indexPrice   |-> [i \in 1 .. 8 |-> 0],
      markPrice    |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Info Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfoMessage ==
    { ZeroInstrumentInfoMessage }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.minSellPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.maxBuyPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.indexPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentInfoMessage EXCEPT !.markPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Ref Message: 48 bytes                                        *)
(***************************************************************************)

InstrumentRefMessage ==
    [ instrumentId           : Sample(8),
      currentFunding         : Sample(8),
      funding8h              : Sample(8),
      estimatedDeliveryPrice : Sample(8),
      deliveryPrice          : Sample(8),
      settlementPrice        : Sample(8) ]

EncodeInstrumentRefMessage(message) ==
    message.instrumentId
        \o message.currentFunding
        \o message.funding8h
        \o message.estimatedDeliveryPrice
        \o message.deliveryPrice
        \o message.settlementPrice

DecodeInstrumentRefMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET currentFunding == ReadBytes(instrumentId.rest, 8) IN IF ~currentFunding.ok THEN Fail ELSE
    LET funding8h == ReadBytes(currentFunding.rest, 8) IN IF ~funding8h.ok THEN Fail ELSE
    LET estimatedDeliveryPrice == ReadBytes(funding8h.rest, 8) IN IF ~estimatedDeliveryPrice.ok THEN Fail ELSE
    LET deliveryPrice == ReadBytes(estimatedDeliveryPrice.rest, 8) IN IF ~deliveryPrice.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(deliveryPrice.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    Ok([ instrumentId           |-> instrumentId.value,
         currentFunding         |-> currentFunding.value,
         funding8h              |-> funding8h.value,
         estimatedDeliveryPrice |-> estimatedDeliveryPrice.value,
         deliveryPrice          |-> deliveryPrice.value,
         settlementPrice        |-> settlementPrice.value ], settlementPrice.rest)

ZeroInstrumentRefMessage ==
    [ instrumentId           |-> [i \in 1 .. 8 |-> 0],
      currentFunding         |-> [i \in 1 .. 8 |-> 0],
      funding8h              |-> [i \in 1 .. 8 |-> 0],
      estimatedDeliveryPrice |-> [i \in 1 .. 8 |-> 0],
      deliveryPrice          |-> [i \in 1 .. 8 |-> 0],
      settlementPrice        |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Ref Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentRefMessage ==
    { ZeroInstrumentRefMessage }
        \cup { [ZeroInstrumentRefMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentRefMessage EXCEPT !.currentFunding = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentRefMessage EXCEPT !.funding8h = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentRefMessage EXCEPT !.estimatedDeliveryPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentRefMessage EXCEPT !.deliveryPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentRefMessage EXCEPT !.settlementPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Status Update Message: 9 bytes                               *)
(***************************************************************************)

InstrumentStatusUpdateMessage ==
    [ instrumentId  : Sample(8),
      tradingStatus : Sample(1) ]

EncodeInstrumentStatusUpdateMessage(message) ==
    message.instrumentId
        \o message.tradingStatus

DecodeInstrumentStatusUpdateMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(instrumentId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    Ok([ instrumentId  |-> instrumentId.value,
         tradingStatus |-> tradingStatus.value ], tradingStatus.rest)

ZeroInstrumentStatusUpdateMessage ==
    [ instrumentId  |-> [i \in 1 .. 8 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Status Update Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStatusUpdateMessage ==
    { ZeroInstrumentStatusUpdateMessage }
        \cup { [ZeroInstrumentStatusUpdateMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStatusUpdateMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Put Message: 40 bytes                                               *)
(***************************************************************************)

BidPutMessage ==
    [ orderId          : Sample(8),
      instrumentId     : Sample(8),
      quantityMantissa : Sample(8),
      price            : Sample(8),
      sortOrderId      : Sample(8) ]

EncodeBidPutMessage(message) ==
    message.orderId
        \o message.instrumentId
        \o message.quantityMantissa
        \o message.price
        \o message.sortOrderId

DecodeBidPutMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET quantityMantissa == ReadBytes(instrumentId.rest, 8) IN IF ~quantityMantissa.ok THEN Fail ELSE
    LET price == ReadBytes(quantityMantissa.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET sortOrderId == ReadBytes(price.rest, 8) IN IF ~sortOrderId.ok THEN Fail ELSE
    Ok([ orderId          |-> orderId.value,
         instrumentId     |-> instrumentId.value,
         quantityMantissa |-> quantityMantissa.value,
         price            |-> price.value,
         sortOrderId      |-> sortOrderId.value ], sortOrderId.rest)

ZeroBidPutMessage ==
    [ orderId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 8 |-> 0],
      quantityMantissa |-> [i \in 1 .. 8 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      sortOrderId      |-> [i \in 1 .. 8 |-> 0] ]

(* Bid Put Message at zero, then each field in turn at the values it is checked at *)
CheckedBidPutMessage ==
    { ZeroBidPutMessage }
        \cup { [ZeroBidPutMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroBidPutMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroBidPutMessage EXCEPT !.quantityMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBidPutMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroBidPutMessage EXCEPT !.sortOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Ask Put Message: 40 bytes                                               *)
(***************************************************************************)

AskPutMessage ==
    [ orderId          : Sample(8),
      instrumentId     : Sample(8),
      quantityMantissa : Sample(8),
      price            : Sample(8),
      sortOrderId      : Sample(8) ]

EncodeAskPutMessage(message) ==
    message.orderId
        \o message.instrumentId
        \o message.quantityMantissa
        \o message.price
        \o message.sortOrderId

DecodeAskPutMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET quantityMantissa == ReadBytes(instrumentId.rest, 8) IN IF ~quantityMantissa.ok THEN Fail ELSE
    LET price == ReadBytes(quantityMantissa.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET sortOrderId == ReadBytes(price.rest, 8) IN IF ~sortOrderId.ok THEN Fail ELSE
    Ok([ orderId          |-> orderId.value,
         instrumentId     |-> instrumentId.value,
         quantityMantissa |-> quantityMantissa.value,
         price            |-> price.value,
         sortOrderId      |-> sortOrderId.value ], sortOrderId.rest)

ZeroAskPutMessage ==
    [ orderId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 8 |-> 0],
      quantityMantissa |-> [i \in 1 .. 8 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      sortOrderId      |-> [i \in 1 .. 8 |-> 0] ]

(* Ask Put Message at zero, then each field in turn at the values it is checked at *)
CheckedAskPutMessage ==
    { ZeroAskPutMessage }
        \cup { [ZeroAskPutMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAskPutMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroAskPutMessage EXCEPT !.quantityMantissa = one] : one \in Sample(8) }
        \cup { [ZeroAskPutMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAskPutMessage EXCEPT !.sortOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Bid Qty Reduced Message: 24 bytes                                       *)
(***************************************************************************)

BidQtyReducedMessage ==
    [ orderId          : Sample(8),
      instrumentId     : Sample(8),
      quantityMantissa : Sample(8) ]

EncodeBidQtyReducedMessage(message) ==
    message.orderId
        \o message.instrumentId
        \o message.quantityMantissa

DecodeBidQtyReducedMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET quantityMantissa == ReadBytes(instrumentId.rest, 8) IN IF ~quantityMantissa.ok THEN Fail ELSE
    Ok([ orderId          |-> orderId.value,
         instrumentId     |-> instrumentId.value,
         quantityMantissa |-> quantityMantissa.value ], quantityMantissa.rest)

ZeroBidQtyReducedMessage ==
    [ orderId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 8 |-> 0],
      quantityMantissa |-> [i \in 1 .. 8 |-> 0] ]

(* Bid Qty Reduced Message at zero, then each field in turn at the values it is checked at *)
CheckedBidQtyReducedMessage ==
    { ZeroBidQtyReducedMessage }
        \cup { [ZeroBidQtyReducedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroBidQtyReducedMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroBidQtyReducedMessage EXCEPT !.quantityMantissa = one] : one \in Sample(8) }

(***************************************************************************)
(* Ask Qty Reduced Message: 24 bytes                                       *)
(***************************************************************************)

AskQtyReducedMessage ==
    [ orderId          : Sample(8),
      instrumentId     : Sample(8),
      quantityMantissa : Sample(8) ]

EncodeAskQtyReducedMessage(message) ==
    message.orderId
        \o message.instrumentId
        \o message.quantityMantissa

DecodeAskQtyReducedMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET quantityMantissa == ReadBytes(instrumentId.rest, 8) IN IF ~quantityMantissa.ok THEN Fail ELSE
    Ok([ orderId          |-> orderId.value,
         instrumentId     |-> instrumentId.value,
         quantityMantissa |-> quantityMantissa.value ], quantityMantissa.rest)

ZeroAskQtyReducedMessage ==
    [ orderId          |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 8 |-> 0],
      quantityMantissa |-> [i \in 1 .. 8 |-> 0] ]

(* Ask Qty Reduced Message at zero, then each field in turn at the values it is checked at *)
CheckedAskQtyReducedMessage ==
    { ZeroAskQtyReducedMessage }
        \cup { [ZeroAskQtyReducedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAskQtyReducedMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroAskQtyReducedMessage EXCEPT !.quantityMantissa = one] : one \in Sample(8) }

(***************************************************************************)
(* Bid Delete Message: 16 bytes                                            *)
(***************************************************************************)

BidDeleteMessage ==
    [ orderId      : Sample(8),
      instrumentId : Sample(8) ]

EncodeBidDeleteMessage(message) ==
    message.orderId
        \o message.instrumentId

DecodeBidDeleteMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ orderId      |-> orderId.value,
         instrumentId |-> instrumentId.value ], instrumentId.rest)

ZeroBidDeleteMessage ==
    [ orderId      |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 8 |-> 0] ]

(* Bid Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedBidDeleteMessage ==
    { ZeroBidDeleteMessage }
        \cup { [ZeroBidDeleteMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroBidDeleteMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }

(***************************************************************************)
(* Ask Delete Message: 16 bytes                                            *)
(***************************************************************************)

AskDeleteMessage ==
    [ orderId      : Sample(8),
      instrumentId : Sample(8) ]

EncodeAskDeleteMessage(message) ==
    message.orderId
        \o message.instrumentId

DecodeAskDeleteMessage(bytes) ==
    LET orderId == ReadBytes(bytes, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(orderId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ orderId      |-> orderId.value,
         instrumentId |-> instrumentId.value ], instrumentId.rest)

ZeroAskDeleteMessage ==
    [ orderId      |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 8 |-> 0] ]

(* Ask Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedAskDeleteMessage ==
    { ZeroAskDeleteMessage }
        \cup { [ZeroAskDeleteMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAskDeleteMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Summary Message: 56 bytes                                         *)
(***************************************************************************)

TradeSummaryMessage ==
    [ instrumentId        : Sample(8),
      takerOrderId        : Sample(8),
      totalFilledMantissa : Sample(8),
      deepestPrice        : Sample(8),
      markPrice           : Sample(8),
      indexPrice          : Sample(8),
      tradeCount          : Sample(4),
      takerFlags          : Sample(4) ]

EncodeTradeSummaryMessage(message) ==
    message.instrumentId
        \o message.takerOrderId
        \o message.totalFilledMantissa
        \o message.deepestPrice
        \o message.markPrice
        \o message.indexPrice
        \o message.tradeCount
        \o message.takerFlags

DecodeTradeSummaryMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET takerOrderId == ReadBytes(instrumentId.rest, 8) IN IF ~takerOrderId.ok THEN Fail ELSE
    LET totalFilledMantissa == ReadBytes(takerOrderId.rest, 8) IN IF ~totalFilledMantissa.ok THEN Fail ELSE
    LET deepestPrice == ReadBytes(totalFilledMantissa.rest, 8) IN IF ~deepestPrice.ok THEN Fail ELSE
    LET markPrice == ReadBytes(deepestPrice.rest, 8) IN IF ~markPrice.ok THEN Fail ELSE
    LET indexPrice == ReadBytes(markPrice.rest, 8) IN IF ~indexPrice.ok THEN Fail ELSE
    LET tradeCount == ReadBytes(indexPrice.rest, 4) IN IF ~tradeCount.ok THEN Fail ELSE
    LET takerFlags == ReadBytes(tradeCount.rest, 4) IN IF ~takerFlags.ok THEN Fail ELSE
    Ok([ instrumentId        |-> instrumentId.value,
         takerOrderId        |-> takerOrderId.value,
         totalFilledMantissa |-> totalFilledMantissa.value,
         deepestPrice        |-> deepestPrice.value,
         markPrice           |-> markPrice.value,
         indexPrice          |-> indexPrice.value,
         tradeCount          |-> tradeCount.value,
         takerFlags          |-> takerFlags.value ], takerFlags.rest)

ZeroTradeSummaryMessage ==
    [ instrumentId        |-> [i \in 1 .. 8 |-> 0],
      takerOrderId        |-> [i \in 1 .. 8 |-> 0],
      totalFilledMantissa |-> [i \in 1 .. 8 |-> 0],
      deepestPrice        |-> [i \in 1 .. 8 |-> 0],
      markPrice           |-> [i \in 1 .. 8 |-> 0],
      indexPrice          |-> [i \in 1 .. 8 |-> 0],
      tradeCount          |-> [i \in 1 .. 4 |-> 0],
      takerFlags          |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeSummaryMessage ==
    { ZeroTradeSummaryMessage }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.takerOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.totalFilledMantissa = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.deepestPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.markPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.indexPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.tradeCount = one] : one \in Sample(4) }
        \cup { [ZeroTradeSummaryMessage EXCEPT !.takerFlags = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Message: 44 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ matchId         : Sample(8),
      instrumentId    : Sample(8),
      makerOrderId    : Sample(8),
      fillQtyMantissa : Sample(8),
      fillPrice       : Sample(8),
      makerFlags      : Sample(4) ]

EncodeTradeMessage(message) ==
    message.matchId
        \o message.instrumentId
        \o message.makerOrderId
        \o message.fillQtyMantissa
        \o message.fillPrice
        \o message.makerFlags

DecodeTradeMessage(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(matchId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET makerOrderId == ReadBytes(instrumentId.rest, 8) IN IF ~makerOrderId.ok THEN Fail ELSE
    LET fillQtyMantissa == ReadBytes(makerOrderId.rest, 8) IN IF ~fillQtyMantissa.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQtyMantissa.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET makerFlags == ReadBytes(fillPrice.rest, 4) IN IF ~makerFlags.ok THEN Fail ELSE
    Ok([ matchId         |-> matchId.value,
         instrumentId    |-> instrumentId.value,
         makerOrderId    |-> makerOrderId.value,
         fillQtyMantissa |-> fillQtyMantissa.value,
         fillPrice       |-> fillPrice.value,
         makerFlags      |-> makerFlags.value ], makerFlags.rest)

ZeroTradeMessage ==
    [ matchId         |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 8 |-> 0],
      makerOrderId    |-> [i \in 1 .. 8 |-> 0],
      fillQtyMantissa |-> [i \in 1 .. 8 |-> 0],
      fillPrice       |-> [i \in 1 .. 8 |-> 0],
      makerFlags      |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.makerOrderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.fillQtyMantissa = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.makerFlags = one] : one \in Sample(4) }

(***************************************************************************)
(* Block Trade Message: 78 bytes                                           *)
(***************************************************************************)

BlockTradeMessage ==
    [ matchId           : Sample(8),
      instrumentId      : Sample(8),
      blockTradeId      : Sample(8),
      blockRfqId        : Sample(8),
      fillQtyMantissa   : Sample(8),
      fillPrice         : Sample(8),
      markPrice         : Sample(8),
      indexPrice        : Sample(8),
      impliedVolatility : Sample(8),
      takerFlags        : Sample(4),
      numberOfLegs      : Sample(2) ]

EncodeBlockTradeMessage(message) ==
    message.matchId
        \o message.instrumentId
        \o message.blockTradeId
        \o message.blockRfqId
        \o message.fillQtyMantissa
        \o message.fillPrice
        \o message.markPrice
        \o message.indexPrice
        \o message.impliedVolatility
        \o message.takerFlags
        \o message.numberOfLegs

DecodeBlockTradeMessage(bytes) ==
    LET matchId == ReadBytes(bytes, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(matchId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET blockTradeId == ReadBytes(instrumentId.rest, 8) IN IF ~blockTradeId.ok THEN Fail ELSE
    LET blockRfqId == ReadBytes(blockTradeId.rest, 8) IN IF ~blockRfqId.ok THEN Fail ELSE
    LET fillQtyMantissa == ReadBytes(blockRfqId.rest, 8) IN IF ~fillQtyMantissa.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQtyMantissa.rest, 8) IN IF ~fillPrice.ok THEN Fail ELSE
    LET markPrice == ReadBytes(fillPrice.rest, 8) IN IF ~markPrice.ok THEN Fail ELSE
    LET indexPrice == ReadBytes(markPrice.rest, 8) IN IF ~indexPrice.ok THEN Fail ELSE
    LET impliedVolatility == ReadBytes(indexPrice.rest, 8) IN IF ~impliedVolatility.ok THEN Fail ELSE
    LET takerFlags == ReadBytes(impliedVolatility.rest, 4) IN IF ~takerFlags.ok THEN Fail ELSE
    LET numberOfLegs == ReadBytes(takerFlags.rest, 2) IN IF ~numberOfLegs.ok THEN Fail ELSE
    Ok([ matchId           |-> matchId.value,
         instrumentId      |-> instrumentId.value,
         blockTradeId      |-> blockTradeId.value,
         blockRfqId        |-> blockRfqId.value,
         fillQtyMantissa   |-> fillQtyMantissa.value,
         fillPrice         |-> fillPrice.value,
         markPrice         |-> markPrice.value,
         indexPrice        |-> indexPrice.value,
         impliedVolatility |-> impliedVolatility.value,
         takerFlags        |-> takerFlags.value,
         numberOfLegs      |-> numberOfLegs.value ], numberOfLegs.rest)

ZeroBlockTradeMessage ==
    [ matchId           |-> [i \in 1 .. 8 |-> 0],
      instrumentId      |-> [i \in 1 .. 8 |-> 0],
      blockTradeId      |-> [i \in 1 .. 8 |-> 0],
      blockRfqId        |-> [i \in 1 .. 8 |-> 0],
      fillQtyMantissa   |-> [i \in 1 .. 8 |-> 0],
      fillPrice         |-> [i \in 1 .. 8 |-> 0],
      markPrice         |-> [i \in 1 .. 8 |-> 0],
      indexPrice        |-> [i \in 1 .. 8 |-> 0],
      impliedVolatility |-> [i \in 1 .. 8 |-> 0],
      takerFlags        |-> [i \in 1 .. 4 |-> 0],
      numberOfLegs      |-> [i \in 1 .. 2 |-> 0] ]

(* Block Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBlockTradeMessage ==
    { ZeroBlockTradeMessage }
        \cup { [ZeroBlockTradeMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.blockTradeId = one] : one \in Sample(8) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.blockRfqId = one] : one \in Sample(8) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.fillQtyMantissa = one] : one \in Sample(8) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.fillPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.markPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.indexPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.impliedVolatility = one] : one \in Sample(8) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.takerFlags = one] : one \in Sample(4) }
        \cup { [ZeroBlockTradeMessage EXCEPT !.numberOfLegs = one] : one \in Sample(2) }

(***************************************************************************)
(* Snapshot Header Message: 24 bytes                                       *)
(***************************************************************************)

SnapshotHeaderMessage ==
    [ instrumentId         : Sample(8),
      incrementalTimestamp : Sample(8),
      incrementalSeqNum    : Sample(8) ]

EncodeSnapshotHeaderMessage(message) ==
    message.instrumentId
        \o message.incrementalTimestamp
        \o message.incrementalSeqNum

DecodeSnapshotHeaderMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET incrementalTimestamp == ReadBytes(instrumentId.rest, 8) IN IF ~incrementalTimestamp.ok THEN Fail ELSE
    LET incrementalSeqNum == ReadBytes(incrementalTimestamp.rest, 8) IN IF ~incrementalSeqNum.ok THEN Fail ELSE
    Ok([ instrumentId         |-> instrumentId.value,
         incrementalTimestamp |-> incrementalTimestamp.value,
         incrementalSeqNum    |-> incrementalSeqNum.value ], incrementalSeqNum.rest)

ZeroSnapshotHeaderMessage ==
    [ instrumentId         |-> [i \in 1 .. 8 |-> 0],
      incrementalTimestamp |-> [i \in 1 .. 8 |-> 0],
      incrementalSeqNum    |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Header Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotHeaderMessage ==
    { ZeroSnapshotHeaderMessage }
        \cup { [ZeroSnapshotHeaderMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotHeaderMessage EXCEPT !.incrementalTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotHeaderMessage EXCEPT !.incrementalSeqNum = one] : one \in Sample(8) }

(***************************************************************************)
(* Snapshot Trailer Message: 24 bytes                                      *)
(***************************************************************************)

SnapshotTrailerMessage ==
    [ instrumentId    : Sample(8),
      timestamp       : Sample(8),
      incrementSeqNum : Sample(8) ]

EncodeSnapshotTrailerMessage(message) ==
    message.instrumentId
        \o message.timestamp
        \o message.incrementSeqNum

DecodeSnapshotTrailerMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET timestamp == ReadBytes(instrumentId.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET incrementSeqNum == ReadBytes(timestamp.rest, 8) IN IF ~incrementSeqNum.ok THEN Fail ELSE
    Ok([ instrumentId    |-> instrumentId.value,
         timestamp       |-> timestamp.value,
         incrementSeqNum |-> incrementSeqNum.value ], incrementSeqNum.rest)

ZeroSnapshotTrailerMessage ==
    [ instrumentId    |-> [i \in 1 .. 8 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      incrementSeqNum |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Trailer Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotTrailerMessage ==
    { ZeroSnapshotTrailerMessage }
        \cup { [ZeroSnapshotTrailerMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotTrailerMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotTrailerMessage EXCEPT !.incrementSeqNum = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Cycle Message: 4 bytes                                           *)
(***************************************************************************)

EndOfCycleMessage ==
    [ activeInstrumentCount : Sample(4) ]

EncodeEndOfCycleMessage(message) ==
    message.activeInstrumentCount

DecodeEndOfCycleMessage(bytes) ==
    LET activeInstrumentCount == ReadBytes(bytes, 4) IN IF ~activeInstrumentCount.ok THEN Fail ELSE
    Ok([ activeInstrumentCount |-> activeInstrumentCount.value ], activeInstrumentCount.rest)

ZeroEndOfCycleMessage ==
    [ activeInstrumentCount |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Cycle Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfCycleMessage ==
    { ZeroEndOfCycleMessage }
        \cup { [ZeroEndOfCycleMessage EXCEPT !.activeInstrumentCount = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmit Request Message: 9 bytes                                     *)
(***************************************************************************)

RetransmitRequestMessage ==
    [ beginSeqNum       : Sample(8),
      messageCountShort : Sample(1) ]

EncodeRetransmitRequestMessage(message) ==
    message.beginSeqNum
        \o message.messageCountShort

DecodeRetransmitRequestMessage(bytes) ==
    LET beginSeqNum == ReadBytes(bytes, 8) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET messageCountShort == ReadBytes(beginSeqNum.rest, 1) IN IF ~messageCountShort.ok THEN Fail ELSE
    Ok([ beginSeqNum       |-> beginSeqNum.value,
         messageCountShort |-> messageCountShort.value ], messageCountShort.rest)

ZeroRetransmitRequestMessage ==
    [ beginSeqNum       |-> [i \in 1 .. 8 |-> 0],
      messageCountShort |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmit Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRequestMessage ==
    { ZeroRetransmitRequestMessage }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.beginSeqNum = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequestMessage EXCEPT !.messageCountShort = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmit Reject Message: 49 bytes                                     *)
(***************************************************************************)

RetransmitRejectMessage ==
    [ retryDelayNanos : Sample(8),
      details         : Sample(40),
      reason          : Sample(1) ]

EncodeRetransmitRejectMessage(message) ==
    message.retryDelayNanos
        \o message.details
        \o message.reason

DecodeRetransmitRejectMessage(bytes) ==
    LET retryDelayNanos == ReadBytes(bytes, 8) IN IF ~retryDelayNanos.ok THEN Fail ELSE
    LET details == ReadBytes(retryDelayNanos.rest, 40) IN IF ~details.ok THEN Fail ELSE
    LET reason == ReadBytes(details.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ retryDelayNanos |-> retryDelayNanos.value,
         details         |-> details.value,
         reason          |-> reason.value ], reason.rest)

ZeroRetransmitRejectMessage ==
    [ retryDelayNanos |-> [i \in 1 .. 8 |-> 0],
      details         |-> [i \in 1 .. 40 |-> 0],
      reason          |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmit Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRejectMessage ==
    { ZeroRetransmitRejectMessage }
        \cup { [ZeroRetransmitRejectMessage EXCEPT !.retryDelayNanos = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRejectMessage EXCEPT !.details = one] : one \in Sample(40) }
        \cup { [ZeroRetransmitRejectMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

InstrumentDefinitionMessageCode == 10  \* 0x0a
IndexDefinitionMessageCode == 11  \* 0x0b
InstrumentInfoMessageCode == 14  \* 0x0e
InstrumentRefMessageCode == 15  \* 0x0f
InstrumentStatusUpdateMessageCode == 16  \* 0x10
BidPutMessageCode == 20  \* 0x14
AskPutMessageCode == 21  \* 0x15
BidQtyReducedMessageCode == 22  \* 0x16
AskQtyReducedMessageCode == 23  \* 0x17
BidDeleteMessageCode == 24  \* 0x18
AskDeleteMessageCode == 25  \* 0x19
TradeSummaryMessageCode == 30  \* 0x1e
TradeMessageCode == 31  \* 0x1f
BlockTradeMessageCode == 33  \* 0x21
SnapshotHeaderMessageCode == 100  \* 0x64
SnapshotTrailerMessageCode == 101  \* 0x65
EndOfCycleMessageCode == 119  \* 0x77
RetransmitRequestMessageCode == 200  \* 0xc8
RetransmitRejectMessageCode == 202  \* 0xca

Payload ==
    [ tag : {InstrumentDefinitionMessageCode}, body : InstrumentDefinitionMessage ]
        \cup [ tag : {IndexDefinitionMessageCode}, body : IndexDefinitionMessage ]
        \cup [ tag : {InstrumentInfoMessageCode}, body : InstrumentInfoMessage ]
        \cup [ tag : {InstrumentRefMessageCode}, body : InstrumentRefMessage ]
        \cup [ tag : {InstrumentStatusUpdateMessageCode}, body : InstrumentStatusUpdateMessage ]
        \cup [ tag : {BidPutMessageCode}, body : BidPutMessage ]
        \cup [ tag : {AskPutMessageCode}, body : AskPutMessage ]
        \cup [ tag : {BidQtyReducedMessageCode}, body : BidQtyReducedMessage ]
        \cup [ tag : {AskQtyReducedMessageCode}, body : AskQtyReducedMessage ]
        \cup [ tag : {BidDeleteMessageCode}, body : BidDeleteMessage ]
        \cup [ tag : {AskDeleteMessageCode}, body : AskDeleteMessage ]
        \cup [ tag : {TradeSummaryMessageCode}, body : TradeSummaryMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {BlockTradeMessageCode}, body : BlockTradeMessage ]
        \cup [ tag : {SnapshotHeaderMessageCode}, body : SnapshotHeaderMessage ]
        \cup [ tag : {SnapshotTrailerMessageCode}, body : SnapshotTrailerMessage ]
        \cup [ tag : {EndOfCycleMessageCode}, body : EndOfCycleMessage ]
        \cup [ tag : {RetransmitRequestMessageCode}, body : RetransmitRequestMessage ]
        \cup [ tag : {RetransmitRejectMessageCode}, body : RetransmitRejectMessage ]

EncodePayload(message) ==
    CASE message.tag = InstrumentDefinitionMessageCode -> EncodeInstrumentDefinitionMessage(message.body)
      [] message.tag = IndexDefinitionMessageCode -> EncodeIndexDefinitionMessage(message.body)
      [] message.tag = InstrumentInfoMessageCode -> EncodeInstrumentInfoMessage(message.body)
      [] message.tag = InstrumentRefMessageCode -> EncodeInstrumentRefMessage(message.body)
      [] message.tag = InstrumentStatusUpdateMessageCode -> EncodeInstrumentStatusUpdateMessage(message.body)
      [] message.tag = BidPutMessageCode -> EncodeBidPutMessage(message.body)
      [] message.tag = AskPutMessageCode -> EncodeAskPutMessage(message.body)
      [] message.tag = BidQtyReducedMessageCode -> EncodeBidQtyReducedMessage(message.body)
      [] message.tag = AskQtyReducedMessageCode -> EncodeAskQtyReducedMessage(message.body)
      [] message.tag = BidDeleteMessageCode -> EncodeBidDeleteMessage(message.body)
      [] message.tag = AskDeleteMessageCode -> EncodeAskDeleteMessage(message.body)
      [] message.tag = TradeSummaryMessageCode -> EncodeTradeSummaryMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = BlockTradeMessageCode -> EncodeBlockTradeMessage(message.body)
      [] message.tag = SnapshotHeaderMessageCode -> EncodeSnapshotHeaderMessage(message.body)
      [] message.tag = SnapshotTrailerMessageCode -> EncodeSnapshotTrailerMessage(message.body)
      [] message.tag = EndOfCycleMessageCode -> EncodeEndOfCycleMessage(message.body)
      [] message.tag = RetransmitRequestMessageCode -> EncodeRetransmitRequestMessage(message.body)
      [] message.tag = RetransmitRejectMessageCode -> EncodeRetransmitRejectMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = InstrumentDefinitionMessageCode -> DecodeInstrumentDefinitionMessage(bytes)
              [] tag = IndexDefinitionMessageCode -> DecodeIndexDefinitionMessage(bytes)
              [] tag = InstrumentInfoMessageCode -> DecodeInstrumentInfoMessage(bytes)
              [] tag = InstrumentRefMessageCode -> DecodeInstrumentRefMessage(bytes)
              [] tag = InstrumentStatusUpdateMessageCode -> DecodeInstrumentStatusUpdateMessage(bytes)
              [] tag = BidPutMessageCode -> DecodeBidPutMessage(bytes)
              [] tag = AskPutMessageCode -> DecodeAskPutMessage(bytes)
              [] tag = BidQtyReducedMessageCode -> DecodeBidQtyReducedMessage(bytes)
              [] tag = AskQtyReducedMessageCode -> DecodeAskQtyReducedMessage(bytes)
              [] tag = BidDeleteMessageCode -> DecodeBidDeleteMessage(bytes)
              [] tag = AskDeleteMessageCode -> DecodeAskDeleteMessage(bytes)
              [] tag = TradeSummaryMessageCode -> DecodeTradeSummaryMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = BlockTradeMessageCode -> DecodeBlockTradeMessage(bytes)
              [] tag = SnapshotHeaderMessageCode -> DecodeSnapshotHeaderMessage(bytes)
              [] tag = SnapshotTrailerMessageCode -> DecodeSnapshotTrailerMessage(bytes)
              [] tag = EndOfCycleMessageCode -> DecodeEndOfCycleMessage(bytes)
              [] tag = RetransmitRequestMessageCode -> DecodeRetransmitRequestMessage(bytes)
              [] tag = RetransmitRejectMessageCode -> DecodeRetransmitRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> InstrumentDefinitionMessageCode, body |-> ZeroInstrumentDefinitionMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> InstrumentDefinitionMessageCode, body |-> one] : one \in CheckedInstrumentDefinitionMessage }
        \cup { [tag |-> IndexDefinitionMessageCode, body |-> one] : one \in CheckedIndexDefinitionMessage }
        \cup { [tag |-> InstrumentInfoMessageCode, body |-> one] : one \in CheckedInstrumentInfoMessage }
        \cup { [tag |-> InstrumentRefMessageCode, body |-> one] : one \in CheckedInstrumentRefMessage }
        \cup { [tag |-> InstrumentStatusUpdateMessageCode, body |-> one] : one \in CheckedInstrumentStatusUpdateMessage }
        \cup { [tag |-> BidPutMessageCode, body |-> one] : one \in CheckedBidPutMessage }
        \cup { [tag |-> AskPutMessageCode, body |-> one] : one \in CheckedAskPutMessage }
        \cup { [tag |-> BidQtyReducedMessageCode, body |-> one] : one \in CheckedBidQtyReducedMessage }
        \cup { [tag |-> AskQtyReducedMessageCode, body |-> one] : one \in CheckedAskQtyReducedMessage }
        \cup { [tag |-> BidDeleteMessageCode, body |-> one] : one \in CheckedBidDeleteMessage }
        \cup { [tag |-> AskDeleteMessageCode, body |-> one] : one \in CheckedAskDeleteMessage }
        \cup { [tag |-> TradeSummaryMessageCode, body |-> one] : one \in CheckedTradeSummaryMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> BlockTradeMessageCode, body |-> one] : one \in CheckedBlockTradeMessage }
        \cup { [tag |-> SnapshotHeaderMessageCode, body |-> one] : one \in CheckedSnapshotHeaderMessage }
        \cup { [tag |-> SnapshotTrailerMessageCode, body |-> one] : one \in CheckedSnapshotTrailerMessage }
        \cup { [tag |-> EndOfCycleMessageCode, body |-> one] : one \in CheckedEndOfCycleMessage }
        \cup { [tag |-> RetransmitRequestMessageCode, body |-> one] : one \in CheckedRetransmitRequestMessage }
        \cup { [tag |-> RetransmitRejectMessageCode, body |-> one] : one \in CheckedRetransmitRejectMessage }

(***************************************************************************)
(* Md Message, framed by Message Length                                    *)
(***************************************************************************)

MdMessage ==
    [ schemaVersion : Sample(2),
      messageFlags  : Sample(2),
      transactTime  : Sample(8),
      payload       : Payload,
      padding       : SampleBytes ]

EncodeMdMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaVersion
        \o message.messageFlags
        \o message.transactTime
        \o EncodePayload(message.payload)
        \o message.padding

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMdMessage(message) ==
    LET body == EncodeMdMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMdMessageBody(bytes) ==
    LET templateId == ReadUIntLE(bytes, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaVersion == ReadBytes(templateId.rest, 2) IN IF ~schemaVersion.ok THEN Fail ELSE
    LET messageFlags == ReadBytes(schemaVersion.rest, 2) IN IF ~messageFlags.ok THEN Fail ELSE
    LET transactTime == ReadBytes(messageFlags.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, transactTime.rest) IN IF ~payload.ok THEN Fail ELSE
    LET padding == Ok(payload.rest, << >>) IN IF ~padding.ok THEN Fail ELSE
    Ok([ schemaVersion |-> schemaVersion.value,
         messageFlags  |-> messageFlags.value,
         transactTime  |-> transactTime.value,
         payload       |-> payload.value,
         padding       |-> padding.value ], padding.rest)

DecodeMdMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMdMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMdMessage ==
    [ schemaVersion |-> [i \in 1 .. 2 |-> 0],
      messageFlags  |-> [i \in 1 .. 2 |-> 0],
      transactTime  |-> [i \in 1 .. 8 |-> 0],
      payload       |-> ZeroPayload,
      padding       |-> << >> ]

(* Md Message at zero, then each field in turn at the values it is checked at *)
CheckedMdMessage ==
    { ZeroMdMessage }
        \cup { [ZeroMdMessage EXCEPT !.schemaVersion = one] : one \in Sample(2) }
        \cup { [ZeroMdMessage EXCEPT !.messageFlags = one] : one \in Sample(2) }
        \cup { [ZeroMdMessage EXCEPT !.transactTime = one] : one \in Sample(8) }
        \cup { [ZeroMdMessage EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroMdMessage EXCEPT !.padding = one] : one \in SampleBytes }

(* A run of Md Message, written one after another *)
RECURSIVE EncodeMdMessageList(_)
EncodeMdMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdMessage(Head(messages)) \o EncodeMdMessageList(Tail(messages))

(* As many Md Message as the field that counts them says *)
RECURSIVE ReadMdMessageList(_, _)
ReadMdMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Message of each kind, for the lists that carry them *)
OneMdMessage ==
    { [ZeroMdMessage EXCEPT !.payload = [tag |-> InstrumentDefinitionMessageCode, body |-> ZeroInstrumentDefinitionMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> IndexDefinitionMessageCode, body |-> ZeroIndexDefinitionMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> InstrumentInfoMessageCode, body |-> ZeroInstrumentInfoMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> InstrumentRefMessageCode, body |-> ZeroInstrumentRefMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> InstrumentStatusUpdateMessageCode, body |-> ZeroInstrumentStatusUpdateMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> BidPutMessageCode, body |-> ZeroBidPutMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> AskPutMessageCode, body |-> ZeroAskPutMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> BidQtyReducedMessageCode, body |-> ZeroBidQtyReducedMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> AskQtyReducedMessageCode, body |-> ZeroAskQtyReducedMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> BidDeleteMessageCode, body |-> ZeroBidDeleteMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> AskDeleteMessageCode, body |-> ZeroAskDeleteMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> TradeSummaryMessageCode, body |-> ZeroTradeSummaryMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> BlockTradeMessageCode, body |-> ZeroBlockTradeMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> SnapshotHeaderMessageCode, body |-> ZeroSnapshotHeaderMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> SnapshotTrailerMessageCode, body |-> ZeroSnapshotTrailerMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> EndOfCycleMessageCode, body |-> ZeroEndOfCycleMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> RetransmitRequestMessageCode, body |-> ZeroRetransmitRequestMessage]],
      [ZeroMdMessage EXCEPT !.payload = [tag |-> RetransmitRejectMessageCode, body |-> ZeroRetransmitRejectMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sendingTime : Sample(8),
      seqNum      : Sample(8),
      channelId   : Sample(4),
      packetType  : Sample(2),
      mdMessage   : SampleLists(OneMdMessage) ]

EncodePacket(message) ==
    message.sendingTime
        \o message.seqNum
        \o message.channelId
        \o message.packetType
        \o EncodeUIntLE(Len(message.mdMessage), 2)
        \o EncodeMdMessageList(message.mdMessage)

DecodePacket(bytes) ==
    LET sendingTime == ReadBytes(bytes, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET seqNum == ReadBytes(sendingTime.rest, 8) IN IF ~seqNum.ok THEN Fail ELSE
    LET channelId == ReadBytes(seqNum.rest, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET packetType == ReadBytes(channelId.rest, 2) IN IF ~packetType.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(packetType.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET mdMessage == ReadMdMessageList(messageCount.rest, messageCount.value) IN IF ~mdMessage.ok THEN Fail ELSE
    Ok([ sendingTime |-> sendingTime.value,
         seqNum      |-> seqNum.value,
         channelId   |-> channelId.value,
         packetType  |-> packetType.value,
         mdMessage   |-> mdMessage.value ], mdMessage.rest)

ZeroPacket ==
    [ sendingTime |-> [i \in 1 .. 8 |-> 0],
      seqNum      |-> [i \in 1 .. 8 |-> 0],
      channelId   |-> [i \in 1 .. 4 |-> 0],
      packetType  |-> [i \in 1 .. 2 |-> 0],
      mdMessage   |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.packetType = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.mdMessage = one] : one \in SampleLists(OneMdMessage) }

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

(* Every Instrument Definition Message large Tick Sizes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDefinitionMessageLargeTickSizesGroup ==
    \A message \in CheckedInstrumentDefinitionMessageLargeTickSizesGroup :
        LET read == DecodeInstrumentDefinitionMessageLargeTickSizesGroup(EncodeInstrumentDefinitionMessageLargeTickSizesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Definition Message large Tick Sizes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDefinitionMessageLargeTickSizesGroups ==
    \A message \in CheckedInstrumentDefinitionMessageLargeTickSizesGroups :
        LET read == DecodeInstrumentDefinitionMessageLargeTickSizesGroups(EncodeInstrumentDefinitionMessageLargeTickSizesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Definition Message legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDefinitionMessageLegsGroup ==
    \A message \in CheckedInstrumentDefinitionMessageLegsGroup :
        LET read == DecodeInstrumentDefinitionMessageLegsGroup(EncodeInstrumentDefinitionMessageLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Definition Message legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDefinitionMessageLegsGroups ==
    \A message \in CheckedInstrumentDefinitionMessageLegsGroups :
        LET read == DecodeInstrumentDefinitionMessageLegsGroups(EncodeInstrumentDefinitionMessageLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDefinitionMessage ==
    \A message \in CheckedInstrumentDefinitionMessage :
        LET read == DecodeInstrumentDefinitionMessage(EncodeInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexDefinitionMessage ==
    \A message \in CheckedIndexDefinitionMessage :
        LET read == DecodeIndexDefinitionMessage(EncodeIndexDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Info Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfoMessage ==
    \A message \in CheckedInstrumentInfoMessage :
        LET read == DecodeInstrumentInfoMessage(EncodeInstrumentInfoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Ref Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentRefMessage ==
    \A message \in CheckedInstrumentRefMessage :
        LET read == DecodeInstrumentRefMessage(EncodeInstrumentRefMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Status Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStatusUpdateMessage ==
    \A message \in CheckedInstrumentStatusUpdateMessage :
        LET read == DecodeInstrumentStatusUpdateMessage(EncodeInstrumentStatusUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Put Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBidPutMessage ==
    \A message \in CheckedBidPutMessage :
        LET read == DecodeBidPutMessage(EncodeBidPutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Put Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAskPutMessage ==
    \A message \in CheckedAskPutMessage :
        LET read == DecodeAskPutMessage(EncodeAskPutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Qty Reduced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQtyReducedMessage ==
    \A message \in CheckedBidQtyReducedMessage :
        LET read == DecodeBidQtyReducedMessage(EncodeBidQtyReducedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Qty Reduced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQtyReducedMessage ==
    \A message \in CheckedAskQtyReducedMessage :
        LET read == DecodeAskQtyReducedMessage(EncodeAskQtyReducedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBidDeleteMessage ==
    \A message \in CheckedBidDeleteMessage :
        LET read == DecodeBidDeleteMessage(EncodeBidDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAskDeleteMessage ==
    \A message \in CheckedAskDeleteMessage :
        LET read == DecodeAskDeleteMessage(EncodeAskDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeSummaryMessage ==
    \A message \in CheckedTradeSummaryMessage :
        LET read == DecodeTradeSummaryMessage(EncodeTradeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Block Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBlockTradeMessage ==
    \A message \in CheckedBlockTradeMessage :
        LET read == DecodeBlockTradeMessage(EncodeBlockTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Header Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotHeaderMessage ==
    \A message \in CheckedSnapshotHeaderMessage :
        LET read == DecodeSnapshotHeaderMessage(EncodeSnapshotHeaderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Trailer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotTrailerMessage ==
    \A message \in CheckedSnapshotTrailerMessage :
        LET read == DecodeSnapshotTrailerMessage(EncodeSnapshotTrailerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Cycle Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfCycleMessage ==
    \A message \in CheckedEndOfCycleMessage :
        LET read == DecodeEndOfCycleMessage(EncodeEndOfCycleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRequestMessage ==
    \A message \in CheckedRetransmitRequestMessage :
        LET read == DecodeRetransmitRequestMessage(EncodeRetransmitRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmit Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRejectMessage ==
    \A message \in CheckedRetransmitRejectMessage :
        LET read == DecodeRetransmitRejectMessage(EncodeRetransmitRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMdMessage ==
    \A message \in CheckedMdMessage :
        LET read == DecodeMdMessage(EncodeMdMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMdMessage ==
    \A message \in CheckedMdMessage :
        LET bytes == EncodeMdMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
