------------------ MODULE LmeSelect_DailySummaries_v4_18 -------------------
(***************************************************************************)
(* The London Metal Exchange LMEsource DailySummaries v4.18                *)
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
(* Sequence Reset Message: 4 bytes                                         *)
(***************************************************************************)

SequenceResetMessage ==
    [ newSeqNo : Sample(4) ]

EncodeSequenceResetMessage(message) ==
    message.newSeqNo

DecodeSequenceResetMessage(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    Ok([ newSeqNo |-> newSeqNo.value ], newSeqNo.rest)

ZeroSequenceResetMessage ==
    [ newSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceResetMessage ==
    { ZeroSequenceResetMessage }
        \cup { [ZeroSequenceResetMessage EXCEPT !.newSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Open Interest Message: 32 bytes                                         *)
(***************************************************************************)

OpenInterestMessage ==
    [ businessDate     : Sample(4),
      openInterestType : Sample(1),
      instrumentId     : Sample(8),
      productCode      : Sample(2),
      contractCode     : Sample(12),
      contractType     : Sample(1),
      volume           : Sample(4) ]

EncodeOpenInterestMessage(message) ==
    message.businessDate
        \o message.openInterestType
        \o message.instrumentId
        \o message.productCode
        \o message.contractCode
        \o message.contractType
        \o message.volume

DecodeOpenInterestMessage(bytes) ==
    LET businessDate == ReadBytes(bytes, 4) IN IF ~businessDate.ok THEN Fail ELSE
    LET openInterestType == ReadBytes(businessDate.rest, 1) IN IF ~openInterestType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(openInterestType.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET productCode == ReadBytes(instrumentId.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET contractCode == ReadBytes(productCode.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET contractType == ReadBytes(contractCode.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET volume == ReadBytes(contractType.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ businessDate     |-> businessDate.value,
         openInterestType |-> openInterestType.value,
         instrumentId     |-> instrumentId.value,
         productCode      |-> productCode.value,
         contractCode     |-> contractCode.value,
         contractType     |-> contractType.value,
         volume           |-> volume.value ], volume.rest)

ZeroOpenInterestMessage ==
    [ businessDate     |-> [i \in 1 .. 4 |-> 0],
      openInterestType |-> [i \in 1 .. 1 |-> 0],
      instrumentId     |-> [i \in 1 .. 8 |-> 0],
      productCode      |-> [i \in 1 .. 2 |-> 0],
      contractCode     |-> [i \in 1 .. 12 |-> 0],
      contractType     |-> [i \in 1 .. 1 |-> 0],
      volume           |-> [i \in 1 .. 4 |-> 0] ]

(* Open Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestMessage ==
    { ZeroOpenInterestMessage }
        \cup { [ZeroOpenInterestMessage EXCEPT !.businessDate = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.openInterestType = one] : one \in Sample(1) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroOpenInterestMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Date Bands: 12 bytes                                                    *)
(***************************************************************************)

DateBands ==
    [ fromDate : Sample(4),
      toDate   : Sample(4),
      volume   : Sample(4) ]

EncodeDateBands(message) ==
    message.fromDate
        \o message.toDate
        \o message.volume

DecodeDateBands(bytes) ==
    LET fromDate == ReadBytes(bytes, 4) IN IF ~fromDate.ok THEN Fail ELSE
    LET toDate == ReadBytes(fromDate.rest, 4) IN IF ~toDate.ok THEN Fail ELSE
    LET volume == ReadBytes(toDate.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ fromDate |-> fromDate.value,
         toDate   |-> toDate.value,
         volume   |-> volume.value ], volume.rest)

ZeroDateBands ==
    [ fromDate |-> [i \in 1 .. 4 |-> 0],
      toDate   |-> [i \in 1 .. 4 |-> 0],
      volume   |-> [i \in 1 .. 4 |-> 0] ]

(* Date Bands at zero, then each field in turn at the values it is checked at *)
CheckedDateBands ==
    { ZeroDateBands }
        \cup { [ZeroDateBands EXCEPT !.fromDate = one] : one \in Sample(4) }
        \cup { [ZeroDateBands EXCEPT !.toDate = one] : one \in Sample(4) }
        \cup { [ZeroDateBands EXCEPT !.volume = one] : one \in Sample(4) }

(* A run of Date Bands, written one after another *)
RECURSIVE EncodeDateBandsList(_)
EncodeDateBandsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDateBands(Head(messages)) \o EncodeDateBandsList(Tail(messages))

(* As many Date Bands as the field that counts them says *)
RECURSIVE ReadDateBandsList(_, _)
ReadDateBandsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDateBands(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDateBandsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Date Bands of each kind, for the lists that carry them *)
OneDateBands == { ZeroDateBands }

(***************************************************************************)
(* Open Interest Band Message                                              *)
(***************************************************************************)

OpenInterestBandMessage ==
    [ businessDate : Sample(4),
      productCode  : Sample(2),
      contractCode : Sample(12),
      contractType : Sample(1),
      currencyCode : Sample(3),
      dateBands    : SampleLists(OneDateBands) ]

EncodeOpenInterestBandMessage(message) ==
    message.businessDate
        \o message.productCode
        \o message.contractCode
        \o message.contractType
        \o message.currencyCode
        \o EncodeUIntLE(Len(message.dateBands), 4)
        \o EncodeDateBandsList(message.dateBands)

DecodeOpenInterestBandMessage(bytes) ==
    LET businessDate == ReadBytes(bytes, 4) IN IF ~businessDate.ok THEN Fail ELSE
    LET productCode == ReadBytes(businessDate.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET contractCode == ReadBytes(productCode.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET contractType == ReadBytes(contractCode.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(contractType.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET dateBandCount == ReadUIntLE(currencyCode.rest, 4) IN IF ~dateBandCount.ok THEN Fail ELSE
    LET dateBands == ReadDateBandsList(dateBandCount.rest, dateBandCount.value) IN IF ~dateBands.ok THEN Fail ELSE
    Ok([ businessDate |-> businessDate.value,
         productCode  |-> productCode.value,
         contractCode |-> contractCode.value,
         contractType |-> contractType.value,
         currencyCode |-> currencyCode.value,
         dateBands    |-> dateBands.value ], dateBands.rest)

ZeroOpenInterestBandMessage ==
    [ businessDate |-> [i \in 1 .. 4 |-> 0],
      productCode  |-> [i \in 1 .. 2 |-> 0],
      contractCode |-> [i \in 1 .. 12 |-> 0],
      contractType |-> [i \in 1 .. 1 |-> 0],
      currencyCode |-> [i \in 1 .. 3 |-> 0],
      dateBands    |-> << >> ]

(* Open Interest Band Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenInterestBandMessage ==
    { ZeroOpenInterestBandMessage }
        \cup { [ZeroOpenInterestBandMessage EXCEPT !.businessDate = one] : one \in Sample(4) }
        \cup { [ZeroOpenInterestBandMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroOpenInterestBandMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroOpenInterestBandMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroOpenInterestBandMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroOpenInterestBandMessage EXCEPT !.dateBands = one] : one \in SampleLists(OneDateBands) }

(***************************************************************************)
(* Long Prompt Dates: 14 bytes                                             *)
(***************************************************************************)

LongPromptDates ==
    [ promptDateLabel  : Sample(6),
      expiryDate       : Sample(4),
      participantCount : Sample(4) ]

EncodeLongPromptDates(message) ==
    message.promptDateLabel
        \o message.expiryDate
        \o message.participantCount

DecodeLongPromptDates(bytes) ==
    LET promptDateLabel == ReadBytes(bytes, 6) IN IF ~promptDateLabel.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(promptDateLabel.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET participantCount == ReadBytes(expiryDate.rest, 4) IN IF ~participantCount.ok THEN Fail ELSE
    Ok([ promptDateLabel  |-> promptDateLabel.value,
         expiryDate       |-> expiryDate.value,
         participantCount |-> participantCount.value ], participantCount.rest)

ZeroLongPromptDates ==
    [ promptDateLabel  |-> [i \in 1 .. 6 |-> 0],
      expiryDate       |-> [i \in 1 .. 4 |-> 0],
      participantCount |-> [i \in 1 .. 4 |-> 0] ]

(* Long Prompt Dates at zero, then each field in turn at the values it is checked at *)
CheckedLongPromptDates ==
    { ZeroLongPromptDates }
        \cup { [ZeroLongPromptDates EXCEPT !.promptDateLabel = one] : one \in Sample(6) }
        \cup { [ZeroLongPromptDates EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroLongPromptDates EXCEPT !.participantCount = one] : one \in Sample(4) }

(* A run of Long Prompt Dates, written one after another *)
RECURSIVE EncodeLongPromptDatesList(_)
EncodeLongPromptDatesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongPromptDates(Head(messages)) \o EncodeLongPromptDatesList(Tail(messages))

(* As many Long Prompt Dates as the field that counts them says *)
RECURSIVE ReadLongPromptDatesList(_, _)
ReadLongPromptDatesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongPromptDates(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongPromptDatesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Prompt Dates of each kind, for the lists that carry them *)
OneLongPromptDates == { ZeroLongPromptDates }

(***************************************************************************)
(* Long Position Bands                                                     *)
(***************************************************************************)

LongPositionBands ==
    [ longPositionLowerValue : Sample(8),
      longPositionUpperValue : Sample(8),
      longPromptDates        : SampleLists(OneLongPromptDates) ]

EncodeLongPositionBands(message) ==
    message.longPositionLowerValue
        \o message.longPositionUpperValue
        \o EncodeUIntLE(Len(message.longPromptDates), 4)
        \o EncodeLongPromptDatesList(message.longPromptDates)

DecodeLongPositionBands(bytes) ==
    LET longPositionLowerValue == ReadBytes(bytes, 8) IN IF ~longPositionLowerValue.ok THEN Fail ELSE
    LET longPositionUpperValue == ReadBytes(longPositionLowerValue.rest, 8) IN IF ~longPositionUpperValue.ok THEN Fail ELSE
    LET longPositionPromptDateCount == ReadUIntLE(longPositionUpperValue.rest, 4) IN IF ~longPositionPromptDateCount.ok THEN Fail ELSE
    LET longPromptDates == ReadLongPromptDatesList(longPositionPromptDateCount.rest, longPositionPromptDateCount.value) IN IF ~longPromptDates.ok THEN Fail ELSE
    Ok([ longPositionLowerValue |-> longPositionLowerValue.value,
         longPositionUpperValue |-> longPositionUpperValue.value,
         longPromptDates        |-> longPromptDates.value ], longPromptDates.rest)

ZeroLongPositionBands ==
    [ longPositionLowerValue |-> [i \in 1 .. 8 |-> 0],
      longPositionUpperValue |-> [i \in 1 .. 8 |-> 0],
      longPromptDates        |-> << >> ]

(* Long Position Bands at zero, then each field in turn at the values it is checked at *)
CheckedLongPositionBands ==
    { ZeroLongPositionBands }
        \cup { [ZeroLongPositionBands EXCEPT !.longPositionLowerValue = one] : one \in Sample(8) }
        \cup { [ZeroLongPositionBands EXCEPT !.longPositionUpperValue = one] : one \in Sample(8) }
        \cup { [ZeroLongPositionBands EXCEPT !.longPromptDates = one] : one \in SampleLists(OneLongPromptDates) }

(* A run of Long Position Bands, written one after another *)
RECURSIVE EncodeLongPositionBandsList(_)
EncodeLongPositionBandsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLongPositionBands(Head(messages)) \o EncodeLongPositionBandsList(Tail(messages))

(* As many Long Position Bands as the field that counts them says *)
RECURSIVE ReadLongPositionBandsList(_, _)
ReadLongPositionBandsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLongPositionBands(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLongPositionBandsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Long Position Bands of each kind, for the lists that carry them *)
OneLongPositionBands == { ZeroLongPositionBands }

(***************************************************************************)
(* Short Prompt Dates: 14 bytes                                            *)
(***************************************************************************)

ShortPromptDates ==
    [ promptDateLabel  : Sample(6),
      expiryDate       : Sample(4),
      participantCount : Sample(4) ]

EncodeShortPromptDates(message) ==
    message.promptDateLabel
        \o message.expiryDate
        \o message.participantCount

DecodeShortPromptDates(bytes) ==
    LET promptDateLabel == ReadBytes(bytes, 6) IN IF ~promptDateLabel.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(promptDateLabel.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET participantCount == ReadBytes(expiryDate.rest, 4) IN IF ~participantCount.ok THEN Fail ELSE
    Ok([ promptDateLabel  |-> promptDateLabel.value,
         expiryDate       |-> expiryDate.value,
         participantCount |-> participantCount.value ], participantCount.rest)

ZeroShortPromptDates ==
    [ promptDateLabel  |-> [i \in 1 .. 6 |-> 0],
      expiryDate       |-> [i \in 1 .. 4 |-> 0],
      participantCount |-> [i \in 1 .. 4 |-> 0] ]

(* Short Prompt Dates at zero, then each field in turn at the values it is checked at *)
CheckedShortPromptDates ==
    { ZeroShortPromptDates }
        \cup { [ZeroShortPromptDates EXCEPT !.promptDateLabel = one] : one \in Sample(6) }
        \cup { [ZeroShortPromptDates EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroShortPromptDates EXCEPT !.participantCount = one] : one \in Sample(4) }

(* A run of Short Prompt Dates, written one after another *)
RECURSIVE EncodeShortPromptDatesList(_)
EncodeShortPromptDatesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeShortPromptDates(Head(messages)) \o EncodeShortPromptDatesList(Tail(messages))

(* As many Short Prompt Dates as the field that counts them says *)
RECURSIVE ReadShortPromptDatesList(_, _)
ReadShortPromptDatesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeShortPromptDates(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadShortPromptDatesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Short Prompt Dates of each kind, for the lists that carry them *)
OneShortPromptDates == { ZeroShortPromptDates }

(***************************************************************************)
(* Short Position Bands                                                    *)
(***************************************************************************)

ShortPositionBands ==
    [ shortPositionLowerValue : Sample(8),
      shortPositionUpperValue : Sample(8),
      shortPromptDates        : SampleLists(OneShortPromptDates) ]

EncodeShortPositionBands(message) ==
    message.shortPositionLowerValue
        \o message.shortPositionUpperValue
        \o EncodeUIntLE(Len(message.shortPromptDates), 4)
        \o EncodeShortPromptDatesList(message.shortPromptDates)

DecodeShortPositionBands(bytes) ==
    LET shortPositionLowerValue == ReadBytes(bytes, 8) IN IF ~shortPositionLowerValue.ok THEN Fail ELSE
    LET shortPositionUpperValue == ReadBytes(shortPositionLowerValue.rest, 8) IN IF ~shortPositionUpperValue.ok THEN Fail ELSE
    LET shortPositionPromptDateCount == ReadUIntLE(shortPositionUpperValue.rest, 4) IN IF ~shortPositionPromptDateCount.ok THEN Fail ELSE
    LET shortPromptDates == ReadShortPromptDatesList(shortPositionPromptDateCount.rest, shortPositionPromptDateCount.value) IN IF ~shortPromptDates.ok THEN Fail ELSE
    Ok([ shortPositionLowerValue |-> shortPositionLowerValue.value,
         shortPositionUpperValue |-> shortPositionUpperValue.value,
         shortPromptDates        |-> shortPromptDates.value ], shortPromptDates.rest)

ZeroShortPositionBands ==
    [ shortPositionLowerValue |-> [i \in 1 .. 8 |-> 0],
      shortPositionUpperValue |-> [i \in 1 .. 8 |-> 0],
      shortPromptDates        |-> << >> ]

(* Short Position Bands at zero, then each field in turn at the values it is checked at *)
CheckedShortPositionBands ==
    { ZeroShortPositionBands }
        \cup { [ZeroShortPositionBands EXCEPT !.shortPositionLowerValue = one] : one \in Sample(8) }
        \cup { [ZeroShortPositionBands EXCEPT !.shortPositionUpperValue = one] : one \in Sample(8) }
        \cup { [ZeroShortPositionBands EXCEPT !.shortPromptDates = one] : one \in SampleLists(OneShortPromptDates) }

(* A run of Short Position Bands, written one after another *)
RECURSIVE EncodeShortPositionBandsList(_)
EncodeShortPositionBandsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeShortPositionBands(Head(messages)) \o EncodeShortPositionBandsList(Tail(messages))

(* As many Short Position Bands as the field that counts them says *)
RECURSIVE ReadShortPositionBandsList(_, _)
ReadShortPositionBandsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeShortPositionBands(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadShortPositionBandsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Short Position Bands of each kind, for the lists that carry them *)
OneShortPositionBands == { ZeroShortPositionBands }

(***************************************************************************)
(* Position Band Message                                                   *)
(***************************************************************************)

PositionBandMessage ==
    [ businessDate       : Sample(4),
      productCode        : Sample(2),
      longPositionBands  : SampleLists(OneLongPositionBands),
      shortPositionBands : SampleLists(OneShortPositionBands) ]

EncodePositionBandMessage(message) ==
    message.businessDate
        \o message.productCode
        \o EncodeUIntLE(Len(message.longPositionBands), 4)
        \o EncodeUIntLE(Len(message.shortPositionBands), 4)
        \o EncodeLongPositionBandsList(message.longPositionBands)
        \o EncodeShortPositionBandsList(message.shortPositionBands)

DecodePositionBandMessage(bytes) ==
    LET businessDate == ReadBytes(bytes, 4) IN IF ~businessDate.ok THEN Fail ELSE
    LET productCode == ReadBytes(businessDate.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET longPositionBandCount == ReadUIntLE(productCode.rest, 4) IN IF ~longPositionBandCount.ok THEN Fail ELSE
    LET shortPositionBandCount == ReadUIntLE(longPositionBandCount.rest, 4) IN IF ~shortPositionBandCount.ok THEN Fail ELSE
    LET longPositionBands == ReadLongPositionBandsList(shortPositionBandCount.rest, longPositionBandCount.value) IN IF ~longPositionBands.ok THEN Fail ELSE
    LET shortPositionBands == ReadShortPositionBandsList(longPositionBands.rest, shortPositionBandCount.value) IN IF ~shortPositionBands.ok THEN Fail ELSE
    Ok([ businessDate       |-> businessDate.value,
         productCode        |-> productCode.value,
         longPositionBands  |-> longPositionBands.value,
         shortPositionBands |-> shortPositionBands.value ], shortPositionBands.rest)

ZeroPositionBandMessage ==
    [ businessDate       |-> [i \in 1 .. 4 |-> 0],
      productCode        |-> [i \in 1 .. 2 |-> 0],
      longPositionBands  |-> << >>,
      shortPositionBands |-> << >> ]

(* Position Band Message at zero, then each field in turn at the values it is checked at *)
CheckedPositionBandMessage ==
    { ZeroPositionBandMessage }
        \cup { [ZeroPositionBandMessage EXCEPT !.businessDate = one] : one \in Sample(4) }
        \cup { [ZeroPositionBandMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroPositionBandMessage EXCEPT !.longPositionBands = one] : one \in SampleLists(OneLongPositionBands) }
        \cup { [ZeroPositionBandMessage EXCEPT !.shortPositionBands = one] : one \in SampleLists(OneShortPositionBands) }

(***************************************************************************)
(* Warrant Bands: 20 bytes                                                 *)
(***************************************************************************)

WarrantBands ==
    [ lowerValue       : Sample(8),
      upperValue       : Sample(8),
      participantCount : Sample(4) ]

EncodeWarrantBands(message) ==
    message.lowerValue
        \o message.upperValue
        \o message.participantCount

DecodeWarrantBands(bytes) ==
    LET lowerValue == ReadBytes(bytes, 8) IN IF ~lowerValue.ok THEN Fail ELSE
    LET upperValue == ReadBytes(lowerValue.rest, 8) IN IF ~upperValue.ok THEN Fail ELSE
    LET participantCount == ReadBytes(upperValue.rest, 4) IN IF ~participantCount.ok THEN Fail ELSE
    Ok([ lowerValue       |-> lowerValue.value,
         upperValue       |-> upperValue.value,
         participantCount |-> participantCount.value ], participantCount.rest)

ZeroWarrantBands ==
    [ lowerValue       |-> [i \in 1 .. 8 |-> 0],
      upperValue       |-> [i \in 1 .. 8 |-> 0],
      participantCount |-> [i \in 1 .. 4 |-> 0] ]

(* Warrant Bands at zero, then each field in turn at the values it is checked at *)
CheckedWarrantBands ==
    { ZeroWarrantBands }
        \cup { [ZeroWarrantBands EXCEPT !.lowerValue = one] : one \in Sample(8) }
        \cup { [ZeroWarrantBands EXCEPT !.upperValue = one] : one \in Sample(8) }
        \cup { [ZeroWarrantBands EXCEPT !.participantCount = one] : one \in Sample(4) }

(* A run of Warrant Bands, written one after another *)
RECURSIVE EncodeWarrantBandsList(_)
EncodeWarrantBandsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeWarrantBands(Head(messages)) \o EncodeWarrantBandsList(Tail(messages))

(* As many Warrant Bands as the field that counts them says *)
RECURSIVE ReadWarrantBandsList(_, _)
ReadWarrantBandsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeWarrantBands(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadWarrantBandsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Warrant Bands of each kind, for the lists that carry them *)
OneWarrantBands == { ZeroWarrantBands }

(***************************************************************************)
(* Warrant Band Message                                                    *)
(***************************************************************************)

WarrantBandMessage ==
    [ businessDate       : Sample(4),
      warrantBandType    : Sample(4),
      productCode        : Sample(2),
      unreportedWarrants : Sample(8),
      warrantBands       : SampleLists(OneWarrantBands) ]

EncodeWarrantBandMessage(message) ==
    message.businessDate
        \o message.warrantBandType
        \o message.productCode
        \o message.unreportedWarrants
        \o EncodeUIntLE(Len(message.warrantBands), 4)
        \o EncodeWarrantBandsList(message.warrantBands)

DecodeWarrantBandMessage(bytes) ==
    LET businessDate == ReadBytes(bytes, 4) IN IF ~businessDate.ok THEN Fail ELSE
    LET warrantBandType == ReadBytes(businessDate.rest, 4) IN IF ~warrantBandType.ok THEN Fail ELSE
    LET productCode == ReadBytes(warrantBandType.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET unreportedWarrants == ReadBytes(productCode.rest, 8) IN IF ~unreportedWarrants.ok THEN Fail ELSE
    LET bandCount == ReadUIntLE(unreportedWarrants.rest, 4) IN IF ~bandCount.ok THEN Fail ELSE
    LET warrantBands == ReadWarrantBandsList(bandCount.rest, bandCount.value) IN IF ~warrantBands.ok THEN Fail ELSE
    Ok([ businessDate       |-> businessDate.value,
         warrantBandType    |-> warrantBandType.value,
         productCode        |-> productCode.value,
         unreportedWarrants |-> unreportedWarrants.value,
         warrantBands       |-> warrantBands.value ], warrantBands.rest)

ZeroWarrantBandMessage ==
    [ businessDate       |-> [i \in 1 .. 4 |-> 0],
      warrantBandType    |-> [i \in 1 .. 4 |-> 0],
      productCode        |-> [i \in 1 .. 2 |-> 0],
      unreportedWarrants |-> [i \in 1 .. 8 |-> 0],
      warrantBands       |-> << >> ]

(* Warrant Band Message at zero, then each field in turn at the values it is checked at *)
CheckedWarrantBandMessage ==
    { ZeroWarrantBandMessage }
        \cup { [ZeroWarrantBandMessage EXCEPT !.businessDate = one] : one \in Sample(4) }
        \cup { [ZeroWarrantBandMessage EXCEPT !.warrantBandType = one] : one \in Sample(4) }
        \cup { [ZeroWarrantBandMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroWarrantBandMessage EXCEPT !.unreportedWarrants = one] : one \in Sample(8) }
        \cup { [ZeroWarrantBandMessage EXCEPT !.warrantBands = one] : one \in SampleLists(OneWarrantBands) }

(***************************************************************************)
(* Trading Volume Message: 36 bytes                                        *)
(***************************************************************************)

TradingVolumeMessage ==
    [ businessDate    : Sample(4),
      tradeDate       : Sample(4),
      calculationType : Sample(1),
      instrumentId    : Sample(8),
      productCode     : Sample(2),
      contractCode    : Sample(12),
      contractType    : Sample(1),
      volume          : Sample(4) ]

EncodeTradingVolumeMessage(message) ==
    message.businessDate
        \o message.tradeDate
        \o message.calculationType
        \o message.instrumentId
        \o message.productCode
        \o message.contractCode
        \o message.contractType
        \o message.volume

DecodeTradingVolumeMessage(bytes) ==
    LET businessDate == ReadBytes(bytes, 4) IN IF ~businessDate.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(businessDate.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    LET calculationType == ReadBytes(tradeDate.rest, 1) IN IF ~calculationType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(calculationType.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET productCode == ReadBytes(instrumentId.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET contractCode == ReadBytes(productCode.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET contractType == ReadBytes(contractCode.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET volume == ReadBytes(contractType.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    Ok([ businessDate    |-> businessDate.value,
         tradeDate       |-> tradeDate.value,
         calculationType |-> calculationType.value,
         instrumentId    |-> instrumentId.value,
         productCode     |-> productCode.value,
         contractCode    |-> contractCode.value,
         contractType    |-> contractType.value,
         volume          |-> volume.value ], volume.rest)

ZeroTradingVolumeMessage ==
    [ businessDate    |-> [i \in 1 .. 4 |-> 0],
      tradeDate       |-> [i \in 1 .. 4 |-> 0],
      calculationType |-> [i \in 1 .. 1 |-> 0],
      instrumentId    |-> [i \in 1 .. 8 |-> 0],
      productCode     |-> [i \in 1 .. 2 |-> 0],
      contractCode    |-> [i \in 1 .. 12 |-> 0],
      contractType    |-> [i \in 1 .. 1 |-> 0],
      volume          |-> [i \in 1 .. 4 |-> 0] ]

(* Trading Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingVolumeMessage ==
    { ZeroTradingVolumeMessage }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.businessDate = one] : one \in Sample(4) }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.calculationType = one] : one \in Sample(1) }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.volume = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceResetMessageCode == 100  \* 0x64
OpenInterestMessageCode == 420  \* 0x1a4
OpenInterestBandMessageCode == 421  \* 0x1a5
PositionBandMessageCode == 422  \* 0x1a6
WarrantBandMessageCode == 423  \* 0x1a7
TradingVolumeMessageCode == 424  \* 0x1a8

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {OpenInterestMessageCode}, body : OpenInterestMessage ]
        \cup [ tag : {OpenInterestBandMessageCode}, body : OpenInterestBandMessage ]
        \cup [ tag : {PositionBandMessageCode}, body : PositionBandMessage ]
        \cup [ tag : {WarrantBandMessageCode}, body : WarrantBandMessage ]
        \cup [ tag : {TradingVolumeMessageCode}, body : TradingVolumeMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = OpenInterestMessageCode -> EncodeOpenInterestMessage(message.body)
      [] message.tag = OpenInterestBandMessageCode -> EncodeOpenInterestBandMessage(message.body)
      [] message.tag = PositionBandMessageCode -> EncodePositionBandMessage(message.body)
      [] message.tag = WarrantBandMessageCode -> EncodeWarrantBandMessage(message.body)
      [] message.tag = TradingVolumeMessageCode -> EncodeTradingVolumeMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = OpenInterestMessageCode -> DecodeOpenInterestMessage(bytes)
              [] tag = OpenInterestBandMessageCode -> DecodeOpenInterestBandMessage(bytes)
              [] tag = PositionBandMessageCode -> DecodePositionBandMessage(bytes)
              [] tag = WarrantBandMessageCode -> DecodeWarrantBandMessage(bytes)
              [] tag = TradingVolumeMessageCode -> DecodeTradingVolumeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> OpenInterestMessageCode, body |-> one] : one \in CheckedOpenInterestMessage }
        \cup { [tag |-> OpenInterestBandMessageCode, body |-> one] : one \in CheckedOpenInterestBandMessage }
        \cup { [tag |-> PositionBandMessageCode, body |-> one] : one \in CheckedPositionBandMessage }
        \cup { [tag |-> WarrantBandMessageCode, body |-> one] : one \in CheckedWarrantBandMessage }
        \cup { [tag |-> TradingVolumeMessageCode, body |-> one] : one \in CheckedTradingVolumeMessage }

(***************************************************************************)
(* Messages                                                                *)
(***************************************************************************)

Messages ==
    [ msgSize : 0 .. 255,
      payload : Payload ]

EncodeMessages(message) ==
    EncodeUIntLE(message.msgSize, 2)
        \o EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

DecodeMessages(bytes) ==
    LET msgSize == ReadUIntLE(bytes, 2) IN IF ~msgSize.ok THEN Fail ELSE
    LET msgType == ReadUIntLE(msgSize.rest, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ msgSize |-> msgSize.value,
         payload |-> payload.value ], payload.rest)

ZeroMessages ==
    [ msgSize |-> 0,
      payload |-> ZeroPayload ]

(* Messages at zero, then each field in turn at the values it is checked at *)
CheckedMessages ==
    { ZeroMessages }
        \cup { [ZeroMessages EXCEPT !.msgSize = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessages EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Messages, written one after another *)
RECURSIVE EncodeMessagesList(_)
EncodeMessagesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessages(Head(messages)) \o EncodeMessagesList(Tail(messages))

(* As many Messages as the field that counts them says *)
RECURSIVE ReadMessagesList(_, _)
ReadMessagesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessages(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessagesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Messages of each kind, for the lists that carry them *)
OneMessages ==
    { [ZeroMessages EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> OpenInterestMessageCode, body |-> ZeroOpenInterestMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> OpenInterestBandMessageCode, body |-> ZeroOpenInterestBandMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> PositionBandMessageCode, body |-> ZeroPositionBandMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> WarrantBandMessageCode, body |-> ZeroWarrantBandMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> TradingVolumeMessageCode, body |-> ZeroTradingVolumeMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize  : Sample(2),
      filler   : Sample(1),
      seqNum   : Sample(4),
      sendTime : Sample(8),
      messages : SampleLists(OneMessages) ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntBE(Len(message.messages), 1)
        \o message.filler
        \o message.seqNum
        \o message.sendTime
        \o EncodeMessagesList(message.messages)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET msgCount == ReadUIntBE(pktSize.rest, 1) IN IF ~msgCount.ok THEN Fail ELSE
    LET filler == ReadBytes(msgCount.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET seqNum == ReadBytes(filler.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(seqNum.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET messages == ReadMessagesList(sendTime.rest, msgCount.value) IN IF ~messages.ok THEN Fail ELSE
    Ok([ pktSize  |-> pktSize.value,
         filler   |-> filler.value,
         seqNum   |-> seqNum.value,
         sendTime |-> sendTime.value,
         messages |-> messages.value ], messages.rest)

ZeroPacket ==
    [ pktSize  |-> [i \in 1 .. 2 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0],
      seqNum   |-> [i \in 1 .. 4 |-> 0],
      sendTime |-> [i \in 1 .. 8 |-> 0],
      messages |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.messages = one] : one \in SampleLists(OneMessages) }

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

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenInterestMessage ==
    \A message \in CheckedOpenInterestMessage :
        LET read == DecodeOpenInterestMessage(EncodeOpenInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Date Bands decodes back to what was encoded, and leaves nothing over *)
RoundTripDateBands ==
    \A message \in CheckedDateBands :
        LET read == DecodeDateBands(EncodeDateBands(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Interest Band Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenInterestBandMessage ==
    \A message \in CheckedOpenInterestBandMessage :
        LET read == DecodeOpenInterestBandMessage(EncodeOpenInterestBandMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Prompt Dates decodes back to what was encoded, and leaves nothing over *)
RoundTripLongPromptDates ==
    \A message \in CheckedLongPromptDates :
        LET read == DecodeLongPromptDates(EncodeLongPromptDates(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Long Position Bands decodes back to what was encoded, and leaves nothing over *)
RoundTripLongPositionBands ==
    \A message \in CheckedLongPositionBands :
        LET read == DecodeLongPositionBands(EncodeLongPositionBands(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Prompt Dates decodes back to what was encoded, and leaves nothing over *)
RoundTripShortPromptDates ==
    \A message \in CheckedShortPromptDates :
        LET read == DecodeShortPromptDates(EncodeShortPromptDates(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Position Bands decodes back to what was encoded, and leaves nothing over *)
RoundTripShortPositionBands ==
    \A message \in CheckedShortPositionBands :
        LET read == DecodeShortPositionBands(EncodeShortPositionBands(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Position Band Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPositionBandMessage ==
    \A message \in CheckedPositionBandMessage :
        LET read == DecodePositionBandMessage(EncodePositionBandMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Warrant Bands decodes back to what was encoded, and leaves nothing over *)
RoundTripWarrantBands ==
    \A message \in CheckedWarrantBands :
        LET read == DecodeWarrantBands(EncodeWarrantBands(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Warrant Band Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWarrantBandMessage ==
    \A message \in CheckedWarrantBandMessage :
        LET read == DecodeWarrantBandMessage(EncodeWarrantBandMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingVolumeMessage ==
    \A message \in CheckedTradingVolumeMessage :
        LET read == DecodeTradingVolumeMessage(EncodeTradingVolumeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Messages decodes back to what was encoded, and leaves nothing over *)
RoundTripMessages ==
    \A message \in CheckedMessages :
        LET read == DecodeMessages(EncodeMessages(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
