------------------ MODULE Turquoise_Mifid2PreTrade_v26_3 -------------------
(***************************************************************************)
(* London Stock Exchange MiFID II Pre Trade v26.3                          *)
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
(* Note: Allowed Book Types is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Order Book Update is a bit field set, checked as its 1 byte       *)
(* rather than bit by bit.                                                 *)
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
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp   : Sample(8),
      eventCode   : Sample(1),
      sourceVenue : Sample(2) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode
        \o message.sourceVenue

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(eventCode.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         eventCode   |-> eventCode.value,
         sourceVenue |-> sourceVenue.value ], sourceVenue.rest)

ZeroSystemEventMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0],
      sourceVenue |-> [i \in 1 .. 2 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument Directory Message: 138 bytes                                 *)
(***************************************************************************)

InstrumentDirectoryMessage ==
    [ timestamp                       : Sample(8),
      instrument                      : Sample(8),
      isin                            : Sample(12),
      allowedBookTypes                : Sample(1),
      sourceVenue                     : Sample(2),
      venueInstrumentId               : Sample(11),
      tickId                          : Sample(2),
      reserved8                       : Sample(8),
      dynamicCircuitBreakerTolerances : Sample(8),
      staticCircuitBreakerTolerances  : Sample(8),
      segment                         : Sample(6),
      reserved12                      : Sample(12),
      securityExchange                : Sample(11),
      currency                        : Sample(3),
      partitionId                     : Sample(1),
      reserved4                       : Sample(4),
      averageDailyTurnoverAdt         : Sample(8),
      secondReserved8                 : Sample(8),
      reserved1                       : Sample(1),
      thirdReserved8                  : Sample(8),
      fourthReserved8                 : Sample(8) ]

EncodeInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.isin
        \o message.allowedBookTypes
        \o message.sourceVenue
        \o message.venueInstrumentId
        \o message.tickId
        \o message.reserved8
        \o message.dynamicCircuitBreakerTolerances
        \o message.staticCircuitBreakerTolerances
        \o message.segment
        \o message.reserved12
        \o message.securityExchange
        \o message.currency
        \o message.partitionId
        \o message.reserved4
        \o message.averageDailyTurnoverAdt
        \o message.secondReserved8
        \o message.reserved1
        \o message.thirdReserved8
        \o message.fourthReserved8

DecodeInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET isin == ReadBytes(instrument.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET allowedBookTypes == ReadBytes(isin.rest, 1) IN IF ~allowedBookTypes.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(allowedBookTypes.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET venueInstrumentId == ReadBytes(sourceVenue.rest, 11) IN IF ~venueInstrumentId.ok THEN Fail ELSE
    LET tickId == ReadBytes(venueInstrumentId.rest, 2) IN IF ~tickId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(tickId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET dynamicCircuitBreakerTolerances == ReadBytes(reserved8.rest, 8) IN IF ~dynamicCircuitBreakerTolerances.ok THEN Fail ELSE
    LET staticCircuitBreakerTolerances == ReadBytes(dynamicCircuitBreakerTolerances.rest, 8) IN IF ~staticCircuitBreakerTolerances.ok THEN Fail ELSE
    LET segment == ReadBytes(staticCircuitBreakerTolerances.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(segment.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(reserved12.rest, 11) IN IF ~securityExchange.ok THEN Fail ELSE
    LET currency == ReadBytes(securityExchange.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET partitionId == ReadBytes(currency.rest, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(partitionId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET averageDailyTurnoverAdt == ReadBytes(reserved4.rest, 8) IN IF ~averageDailyTurnoverAdt.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(averageDailyTurnoverAdt.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(secondReserved8.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET thirdReserved8 == ReadBytes(reserved1.rest, 8) IN IF ~thirdReserved8.ok THEN Fail ELSE
    LET fourthReserved8 == ReadBytes(thirdReserved8.rest, 8) IN IF ~fourthReserved8.ok THEN Fail ELSE
    Ok([ timestamp                       |-> timestamp.value,
         instrument                      |-> instrument.value,
         isin                            |-> isin.value,
         allowedBookTypes                |-> allowedBookTypes.value,
         sourceVenue                     |-> sourceVenue.value,
         venueInstrumentId               |-> venueInstrumentId.value,
         tickId                          |-> tickId.value,
         reserved8                       |-> reserved8.value,
         dynamicCircuitBreakerTolerances |-> dynamicCircuitBreakerTolerances.value,
         staticCircuitBreakerTolerances  |-> staticCircuitBreakerTolerances.value,
         segment                         |-> segment.value,
         reserved12                      |-> reserved12.value,
         securityExchange                |-> securityExchange.value,
         currency                        |-> currency.value,
         partitionId                     |-> partitionId.value,
         reserved4                       |-> reserved4.value,
         averageDailyTurnoverAdt         |-> averageDailyTurnoverAdt.value,
         secondReserved8                 |-> secondReserved8.value,
         reserved1                       |-> reserved1.value,
         thirdReserved8                  |-> thirdReserved8.value,
         fourthReserved8                 |-> fourthReserved8.value ], fourthReserved8.rest)

ZeroInstrumentDirectoryMessage ==
    [ timestamp                       |-> [i \in 1 .. 8 |-> 0],
      instrument                      |-> [i \in 1 .. 8 |-> 0],
      isin                            |-> [i \in 1 .. 12 |-> 0],
      allowedBookTypes                |-> [i \in 1 .. 1 |-> 0],
      sourceVenue                     |-> [i \in 1 .. 2 |-> 0],
      venueInstrumentId               |-> [i \in 1 .. 11 |-> 0],
      tickId                          |-> [i \in 1 .. 2 |-> 0],
      reserved8                       |-> [i \in 1 .. 8 |-> 0],
      dynamicCircuitBreakerTolerances |-> [i \in 1 .. 8 |-> 0],
      staticCircuitBreakerTolerances  |-> [i \in 1 .. 8 |-> 0],
      segment                         |-> [i \in 1 .. 6 |-> 0],
      reserved12                      |-> [i \in 1 .. 12 |-> 0],
      securityExchange                |-> [i \in 1 .. 11 |-> 0],
      currency                        |-> [i \in 1 .. 3 |-> 0],
      partitionId                     |-> [i \in 1 .. 1 |-> 0],
      reserved4                       |-> [i \in 1 .. 4 |-> 0],
      averageDailyTurnoverAdt         |-> [i \in 1 .. 8 |-> 0],
      secondReserved8                 |-> [i \in 1 .. 8 |-> 0],
      reserved1                       |-> [i \in 1 .. 1 |-> 0],
      thirdReserved8                  |-> [i \in 1 .. 8 |-> 0],
      fourthReserved8                 |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryMessage ==
    { ZeroInstrumentDirectoryMessage }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.allowedBookTypes = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.venueInstrumentId = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.tickId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.dynamicCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.staticCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.securityExchange = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.averageDailyTurnoverAdt = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.thirdReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.fourthReserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Directory Extended Message: 310 bytes                        *)
(***************************************************************************)

InstrumentDirectoryExtendedMessage ==
    [ timestamp                       : Sample(8),
      instrument                      : Sample(8),
      isin                            : Sample(12),
      sedol                           : Sample(8),
      allowedBookTypes                : Sample(1),
      sourceVenue                     : Sample(2),
      venueInstrumentId               : Sample(11),
      segment                         : Sample(6),
      currency                        : Sample(3),
      tickId                          : Sample(2),
      previousDaysClosingPrice        : Sample(8),
      reserved8                       : Sample(8),
      dynamicCircuitBreakerTolerances : Sample(8),
      staticCircuitBreakerTolerances  : Sample(8),
      firstReserved1                  : Sample(1),
      secondReserved1                 : Sample(1),
      expirationDate                  : Sample(8),
      listingStartDate                : Sample(8),
      listingEndDate                  : Sample(8),
      minimumLotMinimumExecutionSize  : Sample(8),
      lastPriceInPrecedingSession     : Sample(8),
      lastPriceInPrecedingSessionDate : Sample(8),
      thirdReserved1                  : Sample(1),
      secondReserved8                 : Sample(8),
      thirdReserved8                  : Sample(8),
      exMarkerCode                    : Sample(2),
      securityType                    : Sample(1),
      countryOfRegister               : Sample(3),
      exchangeMarketSize              : Sample(8),
      minimumPeakSizeMultiplier       : Sample(8),
      securityMaximumSpread           : Sample(8),
      clearingType                    : Sample(1),
      strikePrice                     : Sample(8),
      securityExchange                : Sample(11),
      reserved12                      : Sample(12),
      fourthReserved1                 : Sample(1),
      fourthReserved8                 : Sample(8),
      fifthReserved8                  : Sample(8),
      partitionId                     : Sample(1),
      sixthReserved8                  : Sample(8),
      seventhReserved8                : Sample(8),
      reserved4                       : Sample(4),
      reserved2                       : Sample(2),
      symbol                          : Sample(8),
      description                     : Sample(40) ]

EncodeInstrumentDirectoryExtendedMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.isin
        \o message.sedol
        \o message.allowedBookTypes
        \o message.sourceVenue
        \o message.venueInstrumentId
        \o message.segment
        \o message.currency
        \o message.tickId
        \o message.previousDaysClosingPrice
        \o message.reserved8
        \o message.dynamicCircuitBreakerTolerances
        \o message.staticCircuitBreakerTolerances
        \o message.firstReserved1
        \o message.secondReserved1
        \o message.expirationDate
        \o message.listingStartDate
        \o message.listingEndDate
        \o message.minimumLotMinimumExecutionSize
        \o message.lastPriceInPrecedingSession
        \o message.lastPriceInPrecedingSessionDate
        \o message.thirdReserved1
        \o message.secondReserved8
        \o message.thirdReserved8
        \o message.exMarkerCode
        \o message.securityType
        \o message.countryOfRegister
        \o message.exchangeMarketSize
        \o message.minimumPeakSizeMultiplier
        \o message.securityMaximumSpread
        \o message.clearingType
        \o message.strikePrice
        \o message.securityExchange
        \o message.reserved12
        \o message.fourthReserved1
        \o message.fourthReserved8
        \o message.fifthReserved8
        \o message.partitionId
        \o message.sixthReserved8
        \o message.seventhReserved8
        \o message.reserved4
        \o message.reserved2
        \o message.symbol
        \o message.description

DecodeInstrumentDirectoryExtendedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET isin == ReadBytes(instrument.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET sedol == ReadBytes(isin.rest, 8) IN IF ~sedol.ok THEN Fail ELSE
    LET allowedBookTypes == ReadBytes(sedol.rest, 1) IN IF ~allowedBookTypes.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(allowedBookTypes.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET venueInstrumentId == ReadBytes(sourceVenue.rest, 11) IN IF ~venueInstrumentId.ok THEN Fail ELSE
    LET segment == ReadBytes(venueInstrumentId.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET currency == ReadBytes(segment.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET tickId == ReadBytes(currency.rest, 2) IN IF ~tickId.ok THEN Fail ELSE
    LET previousDaysClosingPrice == ReadBytes(tickId.rest, 8) IN IF ~previousDaysClosingPrice.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(previousDaysClosingPrice.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET dynamicCircuitBreakerTolerances == ReadBytes(reserved8.rest, 8) IN IF ~dynamicCircuitBreakerTolerances.ok THEN Fail ELSE
    LET staticCircuitBreakerTolerances == ReadBytes(dynamicCircuitBreakerTolerances.rest, 8) IN IF ~staticCircuitBreakerTolerances.ok THEN Fail ELSE
    LET firstReserved1 == ReadBytes(staticCircuitBreakerTolerances.rest, 1) IN IF ~firstReserved1.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(firstReserved1.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(secondReserved1.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET listingStartDate == ReadBytes(expirationDate.rest, 8) IN IF ~listingStartDate.ok THEN Fail ELSE
    LET listingEndDate == ReadBytes(listingStartDate.rest, 8) IN IF ~listingEndDate.ok THEN Fail ELSE
    LET minimumLotMinimumExecutionSize == ReadBytes(listingEndDate.rest, 8) IN IF ~minimumLotMinimumExecutionSize.ok THEN Fail ELSE
    LET lastPriceInPrecedingSession == ReadBytes(minimumLotMinimumExecutionSize.rest, 8) IN IF ~lastPriceInPrecedingSession.ok THEN Fail ELSE
    LET lastPriceInPrecedingSessionDate == ReadBytes(lastPriceInPrecedingSession.rest, 8) IN IF ~lastPriceInPrecedingSessionDate.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(lastPriceInPrecedingSessionDate.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(thirdReserved1.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET thirdReserved8 == ReadBytes(secondReserved8.rest, 8) IN IF ~thirdReserved8.ok THEN Fail ELSE
    LET exMarkerCode == ReadBytes(thirdReserved8.rest, 2) IN IF ~exMarkerCode.ok THEN Fail ELSE
    LET securityType == ReadBytes(exMarkerCode.rest, 1) IN IF ~securityType.ok THEN Fail ELSE
    LET countryOfRegister == ReadBytes(securityType.rest, 3) IN IF ~countryOfRegister.ok THEN Fail ELSE
    LET exchangeMarketSize == ReadBytes(countryOfRegister.rest, 8) IN IF ~exchangeMarketSize.ok THEN Fail ELSE
    LET minimumPeakSizeMultiplier == ReadBytes(exchangeMarketSize.rest, 8) IN IF ~minimumPeakSizeMultiplier.ok THEN Fail ELSE
    LET securityMaximumSpread == ReadBytes(minimumPeakSizeMultiplier.rest, 8) IN IF ~securityMaximumSpread.ok THEN Fail ELSE
    LET clearingType == ReadBytes(securityMaximumSpread.rest, 1) IN IF ~clearingType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(clearingType.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(strikePrice.rest, 11) IN IF ~securityExchange.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(securityExchange.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(reserved12.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET fourthReserved8 == ReadBytes(fourthReserved1.rest, 8) IN IF ~fourthReserved8.ok THEN Fail ELSE
    LET fifthReserved8 == ReadBytes(fourthReserved8.rest, 8) IN IF ~fifthReserved8.ok THEN Fail ELSE
    LET partitionId == ReadBytes(fifthReserved8.rest, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET sixthReserved8 == ReadBytes(partitionId.rest, 8) IN IF ~sixthReserved8.ok THEN Fail ELSE
    LET seventhReserved8 == ReadBytes(sixthReserved8.rest, 8) IN IF ~seventhReserved8.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(seventhReserved8.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved4.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET symbol == ReadBytes(reserved2.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET description == ReadBytes(symbol.rest, 40) IN IF ~description.ok THEN Fail ELSE
    Ok([ timestamp                       |-> timestamp.value,
         instrument                      |-> instrument.value,
         isin                            |-> isin.value,
         sedol                           |-> sedol.value,
         allowedBookTypes                |-> allowedBookTypes.value,
         sourceVenue                     |-> sourceVenue.value,
         venueInstrumentId               |-> venueInstrumentId.value,
         segment                         |-> segment.value,
         currency                        |-> currency.value,
         tickId                          |-> tickId.value,
         previousDaysClosingPrice        |-> previousDaysClosingPrice.value,
         reserved8                       |-> reserved8.value,
         dynamicCircuitBreakerTolerances |-> dynamicCircuitBreakerTolerances.value,
         staticCircuitBreakerTolerances  |-> staticCircuitBreakerTolerances.value,
         firstReserved1                  |-> firstReserved1.value,
         secondReserved1                 |-> secondReserved1.value,
         expirationDate                  |-> expirationDate.value,
         listingStartDate                |-> listingStartDate.value,
         listingEndDate                  |-> listingEndDate.value,
         minimumLotMinimumExecutionSize  |-> minimumLotMinimumExecutionSize.value,
         lastPriceInPrecedingSession     |-> lastPriceInPrecedingSession.value,
         lastPriceInPrecedingSessionDate |-> lastPriceInPrecedingSessionDate.value,
         thirdReserved1                  |-> thirdReserved1.value,
         secondReserved8                 |-> secondReserved8.value,
         thirdReserved8                  |-> thirdReserved8.value,
         exMarkerCode                    |-> exMarkerCode.value,
         securityType                    |-> securityType.value,
         countryOfRegister               |-> countryOfRegister.value,
         exchangeMarketSize              |-> exchangeMarketSize.value,
         minimumPeakSizeMultiplier       |-> minimumPeakSizeMultiplier.value,
         securityMaximumSpread           |-> securityMaximumSpread.value,
         clearingType                    |-> clearingType.value,
         strikePrice                     |-> strikePrice.value,
         securityExchange                |-> securityExchange.value,
         reserved12                      |-> reserved12.value,
         fourthReserved1                 |-> fourthReserved1.value,
         fourthReserved8                 |-> fourthReserved8.value,
         fifthReserved8                  |-> fifthReserved8.value,
         partitionId                     |-> partitionId.value,
         sixthReserved8                  |-> sixthReserved8.value,
         seventhReserved8                |-> seventhReserved8.value,
         reserved4                       |-> reserved4.value,
         reserved2                       |-> reserved2.value,
         symbol                          |-> symbol.value,
         description                     |-> description.value ], description.rest)

ZeroInstrumentDirectoryExtendedMessage ==
    [ timestamp                       |-> [i \in 1 .. 8 |-> 0],
      instrument                      |-> [i \in 1 .. 8 |-> 0],
      isin                            |-> [i \in 1 .. 12 |-> 0],
      sedol                           |-> [i \in 1 .. 8 |-> 0],
      allowedBookTypes                |-> [i \in 1 .. 1 |-> 0],
      sourceVenue                     |-> [i \in 1 .. 2 |-> 0],
      venueInstrumentId               |-> [i \in 1 .. 11 |-> 0],
      segment                         |-> [i \in 1 .. 6 |-> 0],
      currency                        |-> [i \in 1 .. 3 |-> 0],
      tickId                          |-> [i \in 1 .. 2 |-> 0],
      previousDaysClosingPrice        |-> [i \in 1 .. 8 |-> 0],
      reserved8                       |-> [i \in 1 .. 8 |-> 0],
      dynamicCircuitBreakerTolerances |-> [i \in 1 .. 8 |-> 0],
      staticCircuitBreakerTolerances  |-> [i \in 1 .. 8 |-> 0],
      firstReserved1                  |-> [i \in 1 .. 1 |-> 0],
      secondReserved1                 |-> [i \in 1 .. 1 |-> 0],
      expirationDate                  |-> [i \in 1 .. 8 |-> 0],
      listingStartDate                |-> [i \in 1 .. 8 |-> 0],
      listingEndDate                  |-> [i \in 1 .. 8 |-> 0],
      minimumLotMinimumExecutionSize  |-> [i \in 1 .. 8 |-> 0],
      lastPriceInPrecedingSession     |-> [i \in 1 .. 8 |-> 0],
      lastPriceInPrecedingSessionDate |-> [i \in 1 .. 8 |-> 0],
      thirdReserved1                  |-> [i \in 1 .. 1 |-> 0],
      secondReserved8                 |-> [i \in 1 .. 8 |-> 0],
      thirdReserved8                  |-> [i \in 1 .. 8 |-> 0],
      exMarkerCode                    |-> [i \in 1 .. 2 |-> 0],
      securityType                    |-> [i \in 1 .. 1 |-> 0],
      countryOfRegister               |-> [i \in 1 .. 3 |-> 0],
      exchangeMarketSize              |-> [i \in 1 .. 8 |-> 0],
      minimumPeakSizeMultiplier       |-> [i \in 1 .. 8 |-> 0],
      securityMaximumSpread           |-> [i \in 1 .. 8 |-> 0],
      clearingType                    |-> [i \in 1 .. 1 |-> 0],
      strikePrice                     |-> [i \in 1 .. 8 |-> 0],
      securityExchange                |-> [i \in 1 .. 11 |-> 0],
      reserved12                      |-> [i \in 1 .. 12 |-> 0],
      fourthReserved1                 |-> [i \in 1 .. 1 |-> 0],
      fourthReserved8                 |-> [i \in 1 .. 8 |-> 0],
      fifthReserved8                  |-> [i \in 1 .. 8 |-> 0],
      partitionId                     |-> [i \in 1 .. 1 |-> 0],
      sixthReserved8                  |-> [i \in 1 .. 8 |-> 0],
      seventhReserved8                |-> [i \in 1 .. 8 |-> 0],
      reserved4                       |-> [i \in 1 .. 4 |-> 0],
      reserved2                       |-> [i \in 1 .. 2 |-> 0],
      symbol                          |-> [i \in 1 .. 8 |-> 0],
      description                     |-> [i \in 1 .. 40 |-> 0] ]

(* Instrument Directory Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryExtendedMessage ==
    { ZeroInstrumentDirectoryExtendedMessage }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.sedol = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.allowedBookTypes = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.venueInstrumentId = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.tickId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.previousDaysClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.dynamicCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.staticCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.firstReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.listingStartDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.listingEndDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.minimumLotMinimumExecutionSize = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.lastPriceInPrecedingSession = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.lastPriceInPrecedingSessionDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.thirdReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.exMarkerCode = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.securityType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.countryOfRegister = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.exchangeMarketSize = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.minimumPeakSizeMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.securityMaximumSpread = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.clearingType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.securityExchange = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.fourthReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.fifthReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.sixthReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.seventhReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryExtendedMessage EXCEPT !.description = one] : one \in Sample(40) }

(***************************************************************************)
(* Instrument Status Message: 27 bytes                                     *)
(***************************************************************************)

InstrumentStatusMessage ==
    [ timestamp           : Sample(8),
      instrument          : Sample(8),
      sourceVenue         : Sample(2),
      tradingStatus       : Sample(1),
      sessionChangeReason : Sample(1),
      newEndTime          : Sample(6),
      orderBookType       : Sample(1) ]

EncodeInstrumentStatusMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.tradingStatus
        \o message.sessionChangeReason
        \o message.newEndTime
        \o message.orderBookType

DecodeInstrumentStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(sourceVenue.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET sessionChangeReason == ReadBytes(tradingStatus.rest, 1) IN IF ~sessionChangeReason.ok THEN Fail ELSE
    LET newEndTime == ReadBytes(sessionChangeReason.rest, 6) IN IF ~newEndTime.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(newEndTime.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         instrument          |-> instrument.value,
         sourceVenue         |-> sourceVenue.value,
         tradingStatus       |-> tradingStatus.value,
         sessionChangeReason |-> sessionChangeReason.value,
         newEndTime          |-> newEndTime.value,
         orderBookType       |-> orderBookType.value ], orderBookType.rest)

ZeroInstrumentStatusMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrument          |-> [i \in 1 .. 8 |-> 0],
      sourceVenue         |-> [i \in 1 .. 2 |-> 0],
      tradingStatus       |-> [i \in 1 .. 1 |-> 0],
      sessionChangeReason |-> [i \in 1 .. 1 |-> 0],
      newEndTime          |-> [i \in 1 .. 6 |-> 0],
      orderBookType       |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Status Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStatusMessage ==
    { ZeroInstrumentStatusMessage }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.sessionChangeReason = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.newEndTime = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book Clear Message: 19 bytes                                      *)
(***************************************************************************)

OrderBookClearMessage ==
    [ timestamp     : Sample(8),
      sourceVenue   : Sample(2),
      instrument    : Sample(8),
      orderBookType : Sample(1) ]

EncodeOrderBookClearMessage(message) ==
    message.timestamp
        \o message.sourceVenue
        \o message.instrument
        \o message.orderBookType

DecodeOrderBookClearMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(timestamp.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET instrument == ReadBytes(sourceVenue.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(instrument.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         sourceVenue   |-> sourceVenue.value,
         instrument    |-> instrument.value,
         orderBookType |-> orderBookType.value ], orderBookType.rest)

ZeroOrderBookClearMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      sourceVenue   |-> [i \in 1 .. 2 |-> 0],
      instrument    |-> [i \in 1 .. 8 |-> 0],
      orderBookType |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookClearMessage ==
    { ZeroOrderBookClearMessage }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }

(***************************************************************************)
(* Mifid Ii Order Book Update Message: 175 bytes                           *)
(***************************************************************************)

MifidIiOrderBookUpdateMessage ==
    [ timestamp                     : Sample(8),
      instrument                    : Sample(8),
      sourceVenue                   : Sample(2),
      levelIdentifier               : Sample(1),
      updateDateAndTime             : Sample(30),
      instrumentIdentificationCode  : Sample(12),
      orderBookSide                 : Sample(4),
      price                         : Sample(20),
      priceCurrency                 : Sample(3),
      priceNotation                 : Sample(4),
      quantity                      : Sample(20),
      aggregatedNoOfOrdersAndQuotes : Sample(20),
      venue                         : Sample(4),
      tradingSystem                 : Sample(4),
      tradingSystemPhase            : Sample(4),
      publicationDateAndTime        : Sample(30),
      orderBookUpdate               : Sample(1) ]

EncodeMifidIiOrderBookUpdateMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.levelIdentifier
        \o message.updateDateAndTime
        \o message.instrumentIdentificationCode
        \o message.orderBookSide
        \o message.price
        \o message.priceCurrency
        \o message.priceNotation
        \o message.quantity
        \o message.aggregatedNoOfOrdersAndQuotes
        \o message.venue
        \o message.tradingSystem
        \o message.tradingSystemPhase
        \o message.publicationDateAndTime
        \o message.orderBookUpdate

DecodeMifidIiOrderBookUpdateMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET levelIdentifier == ReadBytes(sourceVenue.rest, 1) IN IF ~levelIdentifier.ok THEN Fail ELSE
    LET updateDateAndTime == ReadBytes(levelIdentifier.rest, 30) IN IF ~updateDateAndTime.ok THEN Fail ELSE
    LET instrumentIdentificationCode == ReadBytes(updateDateAndTime.rest, 12) IN IF ~instrumentIdentificationCode.ok THEN Fail ELSE
    LET orderBookSide == ReadBytes(instrumentIdentificationCode.rest, 4) IN IF ~orderBookSide.ok THEN Fail ELSE
    LET price == ReadBytes(orderBookSide.rest, 20) IN IF ~price.ok THEN Fail ELSE
    LET priceCurrency == ReadBytes(price.rest, 3) IN IF ~priceCurrency.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(priceCurrency.rest, 4) IN IF ~priceNotation.ok THEN Fail ELSE
    LET quantity == ReadBytes(priceNotation.rest, 20) IN IF ~quantity.ok THEN Fail ELSE
    LET aggregatedNoOfOrdersAndQuotes == ReadBytes(quantity.rest, 20) IN IF ~aggregatedNoOfOrdersAndQuotes.ok THEN Fail ELSE
    LET venue == ReadBytes(aggregatedNoOfOrdersAndQuotes.rest, 4) IN IF ~venue.ok THEN Fail ELSE
    LET tradingSystem == ReadBytes(venue.rest, 4) IN IF ~tradingSystem.ok THEN Fail ELSE
    LET tradingSystemPhase == ReadBytes(tradingSystem.rest, 4) IN IF ~tradingSystemPhase.ok THEN Fail ELSE
    LET publicationDateAndTime == ReadBytes(tradingSystemPhase.rest, 30) IN IF ~publicationDateAndTime.ok THEN Fail ELSE
    LET orderBookUpdate == ReadBytes(publicationDateAndTime.rest, 1) IN IF ~orderBookUpdate.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         instrument                    |-> instrument.value,
         sourceVenue                   |-> sourceVenue.value,
         levelIdentifier               |-> levelIdentifier.value,
         updateDateAndTime             |-> updateDateAndTime.value,
         instrumentIdentificationCode  |-> instrumentIdentificationCode.value,
         orderBookSide                 |-> orderBookSide.value,
         price                         |-> price.value,
         priceCurrency                 |-> priceCurrency.value,
         priceNotation                 |-> priceNotation.value,
         quantity                      |-> quantity.value,
         aggregatedNoOfOrdersAndQuotes |-> aggregatedNoOfOrdersAndQuotes.value,
         venue                         |-> venue.value,
         tradingSystem                 |-> tradingSystem.value,
         tradingSystemPhase            |-> tradingSystemPhase.value,
         publicationDateAndTime        |-> publicationDateAndTime.value,
         orderBookUpdate               |-> orderBookUpdate.value ], orderBookUpdate.rest)

ZeroMifidIiOrderBookUpdateMessage ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      instrument                    |-> [i \in 1 .. 8 |-> 0],
      sourceVenue                   |-> [i \in 1 .. 2 |-> 0],
      levelIdentifier               |-> [i \in 1 .. 1 |-> 0],
      updateDateAndTime             |-> [i \in 1 .. 30 |-> 0],
      instrumentIdentificationCode  |-> [i \in 1 .. 12 |-> 0],
      orderBookSide                 |-> [i \in 1 .. 4 |-> 0],
      price                         |-> [i \in 1 .. 20 |-> 0],
      priceCurrency                 |-> [i \in 1 .. 3 |-> 0],
      priceNotation                 |-> [i \in 1 .. 4 |-> 0],
      quantity                      |-> [i \in 1 .. 20 |-> 0],
      aggregatedNoOfOrdersAndQuotes |-> [i \in 1 .. 20 |-> 0],
      venue                         |-> [i \in 1 .. 4 |-> 0],
      tradingSystem                 |-> [i \in 1 .. 4 |-> 0],
      tradingSystemPhase            |-> [i \in 1 .. 4 |-> 0],
      publicationDateAndTime        |-> [i \in 1 .. 30 |-> 0],
      orderBookUpdate               |-> [i \in 1 .. 1 |-> 0] ]

(* Mifid Ii Order Book Update Message at zero, then each field in turn at the values it is checked at *)
CheckedMifidIiOrderBookUpdateMessage ==
    { ZeroMifidIiOrderBookUpdateMessage }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.levelIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.updateDateAndTime = one] : one \in Sample(30) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.instrumentIdentificationCode = one] : one \in Sample(12) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.orderBookSide = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.price = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.priceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.priceNotation = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.quantity = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.aggregatedNoOfOrdersAndQuotes = one] : one \in Sample(20) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.venue = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.tradingSystem = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.tradingSystemPhase = one] : one \in Sample(4) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.publicationDateAndTime = one] : one \in Sample(30) }
        \cup { [ZeroMifidIiOrderBookUpdateMessage EXCEPT !.orderBookUpdate = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* 0x53
InstrumentDirectoryMessageCode == 112  \* 0x70
InstrumentDirectoryExtendedMessageCode == 82  \* 0x52
InstrumentStatusMessageCode == 72  \* 0x48
OrderBookClearMessageCode == 121  \* 0x79
MifidIiOrderBookUpdateMessageCode == 98  \* 0x62

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {InstrumentDirectoryExtendedMessageCode}, body : InstrumentDirectoryExtendedMessage ]
        \cup [ tag : {InstrumentStatusMessageCode}, body : InstrumentStatusMessage ]
        \cup [ tag : {OrderBookClearMessageCode}, body : OrderBookClearMessage ]
        \cup [ tag : {MifidIiOrderBookUpdateMessageCode}, body : MifidIiOrderBookUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = InstrumentDirectoryExtendedMessageCode -> EncodeInstrumentDirectoryExtendedMessage(message.body)
      [] message.tag = InstrumentStatusMessageCode -> EncodeInstrumentStatusMessage(message.body)
      [] message.tag = OrderBookClearMessageCode -> EncodeOrderBookClearMessage(message.body)
      [] message.tag = MifidIiOrderBookUpdateMessageCode -> EncodeMifidIiOrderBookUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = InstrumentDirectoryExtendedMessageCode -> DecodeInstrumentDirectoryExtendedMessage(bytes)
              [] tag = InstrumentStatusMessageCode -> DecodeInstrumentStatusMessage(bytes)
              [] tag = OrderBookClearMessageCode -> DecodeOrderBookClearMessage(bytes)
              [] tag = MifidIiOrderBookUpdateMessageCode -> DecodeMifidIiOrderBookUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> InstrumentDirectoryExtendedMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryExtendedMessage }
        \cup { [tag |-> InstrumentStatusMessageCode, body |-> one] : one \in CheckedInstrumentStatusMessage }
        \cup { [tag |-> OrderBookClearMessageCode, body |-> one] : one \in CheckedOrderBookClearMessage }
        \cup { [tag |-> MifidIiOrderBookUpdateMessageCode, body |-> one] : one \in CheckedMifidIiOrderBookUpdateMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDirectoryExtendedMessageCode, body |-> ZeroInstrumentDirectoryExtendedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStatusMessageCode, body |-> ZeroInstrumentStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookClearMessageCode, body |-> ZeroOrderBookClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MifidIiOrderBookUpdateMessageCode, body |-> ZeroMifidIiOrderBookUpdateMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length          : Sample(2),
      marketDataGroup : Sample(1),
      sequenceNumber  : Sample(4),
      message         : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.marketDataGroup
        \o message.sequenceNumber
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(messageCount.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(marketDataGroup.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET message == ReadMessageList(sequenceNumber.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length          |-> length.value,
         marketDataGroup |-> marketDataGroup.value,
         sequenceNumber  |-> sequenceNumber.value,
         message         |-> message.value ], message.rest)

ZeroPacket ==
    [ length          |-> [i \in 1 .. 2 |-> 0],
      marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      message         |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDirectoryMessage ==
    \A message \in CheckedInstrumentDirectoryMessage :
        LET read == DecodeInstrumentDirectoryMessage(EncodeInstrumentDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Directory Extended Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDirectoryExtendedMessage ==
    \A message \in CheckedInstrumentDirectoryExtendedMessage :
        LET read == DecodeInstrumentDirectoryExtendedMessage(EncodeInstrumentDirectoryExtendedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStatusMessage ==
    \A message \in CheckedInstrumentStatusMessage :
        LET read == DecodeInstrumentStatusMessage(EncodeInstrumentStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookClearMessage ==
    \A message \in CheckedOrderBookClearMessage :
        LET read == DecodeOrderBookClearMessage(EncodeOrderBookClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Ii Order Book Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidIiOrderBookUpdateMessage ==
    \A message \in CheckedMifidIiOrderBookUpdateMessage :
        LET read == DecodeMifidIiOrderBookUpdateMessage(EncodeMifidIiOrderBookUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
