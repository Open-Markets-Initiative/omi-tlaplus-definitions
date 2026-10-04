# Omi TLA+ Definitions

Omi [TLA+](https://lamport.azurewebsites.net/tla/tla.html "A language for modelling and checking systems") definitions describe common binary exchange protocols as TLA+ modules, so what the wire format states is checked rather than assumed: every message encodes to the bytes the model states and decodes back to what was encoded.


[![TLA+](https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/About/Images/Tla.png)](https://lamport.azurewebsites.net/tla/tla.html)

These definitions are checked with the TLA+ model checker: [TLC](https://lamport.azurewebsites.net/tla/tools.html "The TLA+ tools")
## Usage

Each .tla file is a self contained module for one protocol version: the wire primitives, one record per group the tree reads, one choice per message dispatch, and the invariants TLC checks over them. Its .cfg sits beside it, naming the invariants to check. Run one with the TLA+ tools:

```
java -cp tla2tools.jar tlc2.TLC iex/iexequities/tops/IexEquities_Tops_v1_56.tla
```
A field is the bytes it occupies; an integer is read only where a rule depends on one — a length, a count, a message type — which are the dependencies the parse rules run on. Each definition is accompanied by a `_Captures` module carrying packets recorded off the wire, which decode and encode back to exactly the bytes they were read from.

For the model checker and its tools: [TLA+ Tools](https://lamport.azurewebsites.net/tla/tools.html "The TLA+ tools")
## Development

Updates are greatly appreciated; however, this entire repository is source generated...including the words you are reading right now. If you wish to suggest definition updates, the recommended process is to create an issue with changes and explanation.  Time permitting, we will update the models and regenerate.

| Protocol Count | Generated Lines |
| --- | --- |
| 440 | 519783 |

## Testing

[![Build](https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/actions/workflows/build.yml/badge.svg)](https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/actions/workflows/build.yml)

Please report any checking errors as an [issue](https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/issues "Omi TLA+ Issues").  Include a small note on the protocol and version, and a minimal capture demonstrating the problem. Also consider including a link or pdf specification documenting the correct behavior.

## Open Markets Initiative

The Open Markets Initiative (Omi) is a group of technologists dedicated to enhancing the stability of electronic financial markets using modern development methods.

Other generated code can be found at [Omi Repositories](https://github.com/Open-Markets-Initiative/Directory/tree/main/Repositories "Open Markets Initiative Repositories"); for Omi rules and regulations, see [Omi Directory](https://github.com/Open-Markets-Initiative/Directory "Open Markets Initiative Directory").
## Organizations

> [Iex][Iex.Directory] · [Nasdaq][Nasdaq.Directory]

## Exchanges

> [BxEquities][BxEquities.Exchange] · [GemxOptions][GemxOptions.Exchange] · [IexEquities][IexEquities.Exchange] · [IexOptions][IexOptions.Exchange] · [IseOptions][IseOptions.Exchange] · [MrxOptions][MrxOptions.Exchange] · [NasdaqCanada][NasdaqCanada.Exchange] · [NfxFutures][NfxFutures.Exchange] · [NomOptions][NomOptions.Exchange] · [NordicDerivatives][NordicDerivatives.Exchange] · [NordicEquities][NordicEquities.Exchange] · [NsmEquities][NsmEquities.Exchange] · [NtxEquities][NtxEquities.Exchange] · [NtxOptions][NtxOptions.Exchange] · [PhlxOptions][PhlxOptions.Exchange] · [PsxEquities][PsxEquities.Exchange]

## Consolidators

> [Uqdf][Uqdf.Consolidator] · [Utdf][Utdf.Consolidator] · [Utp][Utp.Consolidator]

## Related Definitions

The Open Markets Initiative provides protocol definitions in several formats:

- [Kaitai Struct Definitions][Kaitai.Definitions.Repository] — cross language binary parsers with the kaitai struct compiler
- [DFDL Definitions][Dfdl.Definitions.Repository] — declarative DFDL schemas for cross language parsing
- [P4 Definitions][P4.Definitions.Repository] — P4 programs for software and hardware data planes
- [Spicy Definitions][Spicy.Definitions.Repository] — declarative Spicy grammars for the spicy toolchain and the zeek network security monitor
- [Lean Definitions][Lean.Definitions.Repository] — Lean 4 definitions with machine checked encode and decode proofs
- [FIX Dictionaries][Fix.Dictionaries.Repository] — QuickFIX format xml data dictionaries, one per FIX version
- [Xml Specifications][Xml.Specifications.Repository] — the exchange protocol specification xmls, matching the original files
## License

Omi definitions are free software with the least restrictive licensing possible; see the [Omi license terms](https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/tree/main/About/License "Omi License Terms").

The TLA+ logo above is Copyright Edward Lamport and is used under the MIT license, redrawn from the TLA+ splash image published on [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:TLA%2B_logo_splash_image.png "TLA+ logo splash image"):

> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Disclaimer

Any similarities between existing people, places and/or protocols is purely incidental.

Enjoy.

[Omi Repositories]: https://github.com/Open-Markets-Initiative/Directory/tree/main/Repositories "Open Markets Initiative Repositories"
[Omi Rules and Regulations]: https://github.com/Open-Markets-Initiative/Directory/tree/main/License "Open Markets Initiative Rules and Regulations"

[Omi.Glossary.Testing]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Glossary/Testing.md "Protocol Testing Status"
[Omi.Glossary.Testing.Verified]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Glossary/Testing.md "Testing Status: Protocol has been tested on live data"
[Omi.Glossary.Testing.Incomplete]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Glossary/Testing.md "Testing Status: Protocol has been tested on live data but contains known issues"
[Omi.Glossary.Testing.Beta]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Glossary/Testing.md "Testing Status: Protocol has not been tested and structure is speculative"
[Omi.Glossary.Testing.Untested]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Glossary/Testing.md "Testing Status: Protocol has not been tested on live data"
[Omi.Glossary.Testing.Unavailable]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Glossary/Testing.md "Testing Status: Protocol does not state a testing status"
[Omi.Encoding.Definitions]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Protocols/ReadMe.md "Encoding Directory"

[Omi.Encoding.IexTp]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/IexTp.md "IexTp Encoding"
[Omi.Encoding.Snap]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/Snap.md "Snap Encoding"
[Omi.Encoding.Udp]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/Udp.md "Udp Encoding"
[Omi.Encoding.Sbe]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/Sbe.md "Sbe Encoding"
[Omi.Encoding.AsciiDrop]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/AsciiDrop.md "AsciiDrop Encoding"
[Omi.Encoding.AsciiRash]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/AsciiRash.md "AsciiRash Encoding"
[Omi.Encoding.Itch]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/Itch.md "Itch Encoding"
[Omi.Encoding.Glimpse]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/Glimpse.md "Glimpse Encoding"
[Omi.Encoding.Ouch]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/Ouch.md "Ouch Encoding"
[Omi.Encoding.Sqf]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/Sqf.md "Sqf Encoding"
[Omi.Encoding.AsciiItch]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/AsciiItch.md "AsciiItch Encoding"
[Omi.Encoding.GeniumAmd]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/GeniumAmd.md "GeniumAmd Encoding"
[Omi.Encoding.Binary]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/Binary.md "Binary Encoding"
[Omi.Encoding.Utp]: https://github.com/Open-Markets-Initiative/Directory/blob/main/Protocols/Utp.md "Utp Encoding"

[Iex.IexEquities.Deep]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Iex/Protocols/IexEquities/Deep.md "Depth Of Book"
[Iex.IexEquities.DeepPlus]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Iex/Protocols/IexEquities/DeepPlus.md "DeepPlus"
[Iex.IexEquities.IexTpHeader]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Iex/Protocols/IexEquities/IexTpHeader.md "IexTp Header"
[Iex.IexEquities.Tops]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Iex/Protocols/IexEquities/Tops.md "Top Of Book"
[Iex.IexOptions.BinaryOrderEntry]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Iex/Protocols/IexOptions/BinaryOrderEntry.md "Binary Order Entry"
[Iex.IexOptions.MarketData]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Iex/Protocols/IexOptions/MarketData.md "Market Data"
[Iex.IexOptions.Session]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Iex/Protocols/IexOptions/Session.md "Session"
[Nasdaq.BxEquities.Drop]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/BxEquities/Drop.md "Drop"
[Nasdaq.BxEquities.Rash]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/BxEquities/Rash.md "Rash"
[Nasdaq.GemxOptions.Cti]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/GemxOptions/Cti.md "Clearing Trade Interface"
[Nasdaq.GemxOptions.DepthOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/GemxOptions/DepthOfMarket.md "Depth Of Market"
[Nasdaq.GemxOptions.OrderFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/GemxOptions/OrderFeed.md "Order Feed"
[Nasdaq.GemxOptions.Otto]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/GemxOptions/Otto.md "Ouch to Trade Options"
[Nasdaq.GemxOptions.Quoting]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/GemxOptions/Quoting.md "Specialized Quote Interface"
[Nasdaq.GemxOptions.TopOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/GemxOptions/TopOfMarket.md "Top Of Market"
[Nasdaq.GemxOptions.TradeFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/GemxOptions/TradeFeed.md "Trade Feed"
[Nasdaq.IseOptions.Cti]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/Cti.md "Clearing Trade Interface"
[Nasdaq.IseOptions.DepthOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/DepthOfMarket.md "Depth Of Market"
[Nasdaq.IseOptions.OrderComboFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/OrderComboFeed.md "Ise Order Combo Market Data Feed"
[Nasdaq.IseOptions.OrderFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/OrderFeed.md "Ise Order Feed Market Data"
[Nasdaq.IseOptions.Otto]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/Otto.md "Ouch to Trade Options"
[Nasdaq.IseOptions.Quoting]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/Quoting.md "Specialized Quote Interface"
[Nasdaq.IseOptions.SpreadDepthOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/SpreadDepthOfMarket.md "ISE Options Spread Depth"
[Nasdaq.IseOptions.SpreadOrders]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/SpreadOrders.md "ISE Options Spread Orders"
[Nasdaq.IseOptions.SpreadTopOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/SpreadTopOfMarket.md "ISE Options Spread Top Of Market"
[Nasdaq.IseOptions.SpreadTradeFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/SpreadTradeFeed.md "ISE Options Spread Trade Feed"
[Nasdaq.IseOptions.TopComboQuoteFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/TopComboQuoteFeed.md "Ise Top Combo Quote Feed"
[Nasdaq.IseOptions.TopOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/TopOfMarket.md "Top Of Market"
[Nasdaq.IseOptions.TradeFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/IseOptions/TradeFeed.md "Trade Feed"
[Nasdaq.MrxOptions.Cti]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/Cti.md "Clearing Trade Interface"
[Nasdaq.MrxOptions.DepthOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/DepthOfMarket.md "Depth Of Market"
[Nasdaq.MrxOptions.OrderFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/OrderFeed.md "Order Feed"
[Nasdaq.MrxOptions.Otto]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/Otto.md "Ouch to Trade Options"
[Nasdaq.MrxOptions.Quoting]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/Quoting.md "Specialized Quote Interface"
[Nasdaq.MrxOptions.SpreadDepthOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/SpreadDepthOfMarket.md "MRX Options Spread Depth"
[Nasdaq.MrxOptions.SpreadOrders]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/SpreadOrders.md "MRX Options Spread Orders"
[Nasdaq.MrxOptions.SpreadTopOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/SpreadTopOfMarket.md "MRX Options Spread Top Of Market"
[Nasdaq.MrxOptions.SpreadTradeFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/SpreadTradeFeed.md "MRX Options Spread Trade Feed"
[Nasdaq.MrxOptions.TopOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/TopOfMarket.md "Top Of Market"
[Nasdaq.MrxOptions.TradeFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/MrxOptions/TradeFeed.md "Trade Feed"
[Nasdaq.NasdaqCanada.Chixmd]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NasdaqCanada/Chixmd.md "CHIXMD Market Data"
[Nasdaq.NasdaqCanada.Chixmmd]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NasdaqCanada/Chixmmd.md "CHIXMMD Multicast Market Data"
[Nasdaq.NasdaqCanada.OrderEntry]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NasdaqCanada/OrderEntry.md "Nasdaq Canada Order Entry"
[Nasdaq.NfxFutures.MarketData]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NfxFutures/MarketData.md "Genium INET Auxiliary Market Data"
[Nasdaq.NomOptions.Bono]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NomOptions/Bono.md "Nom Binary Order Entry"
[Nasdaq.NomOptions.Cti]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NomOptions/Cti.md "Clearing Trade Interface"
[Nasdaq.NomOptions.Itto]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NomOptions/Itto.md "Itch To Trade Options"
[Nasdaq.NomOptions.Otto]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NomOptions/Otto.md "Ouch to Trade Options"
[Nasdaq.NomOptions.Quoting]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NomOptions/Quoting.md "Specialized Quote Interface"
[Nasdaq.NordicDerivatives.DepthOfBook]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NordicDerivatives/DepthOfBook.md "Genium INET Depth Of Book"
[Nasdaq.NordicDerivatives.MarketData]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NordicDerivatives/MarketData.md "Genium INET Auxiliary Market Data"
[Nasdaq.NordicEquities.LastSale]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NordicEquities/LastSale.md "Nordic Equity Last Sale"
[Nasdaq.NordicEquities.OrderEntry]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NordicEquities/OrderEntry.md "Nordic Ouch 5 Order Entry"
[Nasdaq.NordicEquities.RiskControl]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NordicEquities/RiskControl.md "Nordic Pre-Trade Risk Management"
[Nasdaq.NordicEquities.TotalView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NordicEquities/TotalView.md "Nordic Equity TotalView"
[Nasdaq.NsmEquities.Aggregated]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/Aggregated.md "TotalView Aggregated"
[Nasdaq.NsmEquities.BasicPlus]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/BasicPlus.md "Basic Plus"
[Nasdaq.NsmEquities.Drop]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/Drop.md "Drop"
[Nasdaq.NsmEquities.LastSale]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/LastSale.md "Last Sale"
[Nasdaq.NsmEquities.LastSaleTradesFilterView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/LastSaleTradesFilterView.md "Last Sale Trades FilterView"
[Nasdaq.NsmEquities.LastSaleTrfTradesFilterView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/LastSaleTrfTradesFilterView.md "Last Sale Trf Trades FilterView"
[Nasdaq.NsmEquities.Level2]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/Level2.md "Level 2"
[Nasdaq.NsmEquities.MatchView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/MatchView.md "Match View"
[Nasdaq.NsmEquities.NlsPlus]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/NlsPlus.md "Last Sale Plus"
[Nasdaq.NsmEquities.Nois]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/Nois.md "Net Order Imbalance Snapshot"
[Nasdaq.NsmEquities.NoiView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/NoiView.md "Net Order Imbalance View"
[Nasdaq.NsmEquities.Orders]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/Orders.md "Orders"
[Nasdaq.NsmEquities.Qbbo]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/Qbbo.md "Best Bid And Offer"
[Nasdaq.NsmEquities.Rash]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/Rash.md "Rash"
[Nasdaq.NsmEquities.TotalView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/TotalView.md "TotalView Itch"
[Nasdaq.NsmEquities.TotalViewPlus]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NsmEquities/TotalViewPlus.md "TotalView Plus"
[Nasdaq.NtxEquities.Bbo]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxEquities/Bbo.md "TX Best Bid And Offer"
[Nasdaq.NtxEquities.Drop]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxEquities/Drop.md "Drop"
[Nasdaq.NtxEquities.LastSale]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxEquities/LastSale.md "Last Sale"
[Nasdaq.NtxEquities.MatchView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxEquities/MatchView.md "Match View"
[Nasdaq.NtxEquities.Orders]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxEquities/Orders.md "BX Orders"
[Nasdaq.NtxEquities.Rash]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxEquities/Rash.md "Rash"
[Nasdaq.NtxEquities.TotalView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxEquities/TotalView.md "TX TotalView Itch"
[Nasdaq.NtxOptions.Cti]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxOptions/Cti.md "Clearing Trade Interface"
[Nasdaq.NtxOptions.DepthOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxOptions/DepthOfMarket.md "Depth Of Market"
[Nasdaq.NtxOptions.Quoting]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxOptions/Quoting.md "Specialized Quote Interface"
[Nasdaq.NtxOptions.TopOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxOptions/TopOfMarket.md "Top Of Market"
[Nasdaq.NtxOptions.TradeFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/NtxOptions/TradeFeed.md "Trade Feed"
[Nasdaq.PhlxOptions.Cti]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/Cti.md "Clearing Trade Interface"
[Nasdaq.PhlxOptions.DepthOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/DepthOfMarket.md "Depth Of Market"
[Nasdaq.PhlxOptions.Orders]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/Orders.md "PHLX Orders"
[Nasdaq.PhlxOptions.Otto]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/Otto.md "Ouch to Trade Options"
[Nasdaq.PhlxOptions.Quoting]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/Quoting.md "Specialized Quote Interface"
[Nasdaq.PhlxOptions.SpreadDepthOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/SpreadDepthOfMarket.md "Spread Depth"
[Nasdaq.PhlxOptions.SpreadOrders]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/SpreadOrders.md "Spread Orders"
[Nasdaq.PhlxOptions.SpreadTopOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/SpreadTopOfMarket.md "Spread Top Of Market"
[Nasdaq.PhlxOptions.SpreadTradeFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/SpreadTradeFeed.md "Spread Trade Feed"
[Nasdaq.PhlxOptions.TopOfMarket]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/TopOfMarket.md "Top Of Market"
[Nasdaq.PhlxOptions.TradeFeed]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PhlxOptions/TradeFeed.md "Trade Feed"
[Nasdaq.PsxEquities.Bbo]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PsxEquities/Bbo.md "Best Bid And Offer"
[Nasdaq.PsxEquities.Drop]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PsxEquities/Drop.md "Drop"
[Nasdaq.PsxEquities.LastSale]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PsxEquities/LastSale.md "Last Sale"
[Nasdaq.PsxEquities.MatchView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PsxEquities/MatchView.md "Match View"
[Nasdaq.PsxEquities.Orders]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PsxEquities/Orders.md "Orders"
[Nasdaq.PsxEquities.Rash]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PsxEquities/Rash.md "Rash"
[Nasdaq.PsxEquities.TotalView]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/PsxEquities/TotalView.md "TotalView Itch"
[Nasdaq.Uqdf.Output]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/Uqdf/Output.md "Output"
[Nasdaq.Utdf.Output]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/Utdf/Output.md "Output"
[Nasdaq.Utp.Input]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/Utp/Input.md ""
[Nasdaq.Utp.Snapshot]: https://github.com/Open-Markets-Initiative/Open-Markets-Initiative/blob/main/Organizations/Nasdaq/Protocols/Utp/Snapshot.md "Snapshot"

[Iex.Directory]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/iex "Investors Exchange"
[Nasdaq.Directory]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq "National Association of Securities Dealers Automated Quotations (Nasdaq)"

[BxEquities.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/bxequities "Nasdaq BX"
[GemxOptions.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/gemxoptions "Nasdaq GEMX"
[IexEquities.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/iex/iexequities "IEX Equities"
[IexOptions.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/iex/iexoptions "IEX Options"
[IseOptions.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/iseoptions "Nasdaq ISE"
[MrxOptions.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/mrxoptions "Nasdaq MRX"
[NasdaqCanada.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/nasdaqcanada "Nasdaq Canada"
[NfxFutures.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/nfxfutures "Nasdaq Futures"
[NomOptions.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/nomoptions "Nasdaq Options Market"
[NordicDerivatives.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/nordicderivatives "Nasdaq Nordic Derivatives"
[NordicEquities.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/nordicequities "Nasdaq Nordic Equities"
[NsmEquities.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/nsmequities "Nasdaq Stock Market"
[NtxEquities.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/ntxequities "Nasdaq Texas"
[NtxOptions.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/ntxoptions "Nasdaq Texas Options"
[PhlxOptions.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/phlxoptions "Nasdaq PHLX"
[PsxEquities.Exchange]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/psxequities "Nasdaq PSX"
[Uqdf.Consolidator]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/uqdf "Nasdaq UTP Quote Data Feed"
[Utdf.Consolidator]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/utdf "Nasdaq UTP Trade Data Feed"
[Utp.Consolidator]: https://github.com/Open-Markets-Initiative/omi-tlaplus-definitions/tree/main/nasdaq/utp "Nasdaq Unlisted Trading Privileges Plan"

[Kaitai.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-kaitai-struct-definitions "Omi Kaitai Struct Definitions"
[Dfdl.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-dfdl-definitions "Omi DFDL Definitions"
[P4.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-p4-definitions "Omi P4 Definitions"
[Spicy.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-spicy-definitions "Omi Spicy Definitions"
[Lean.Definitions.Repository]: https://github.com/Open-Markets-Initiative/omi-lean-definitions "Omi Lean Definitions"
[Fix.Dictionaries.Repository]: https://github.com/Open-Markets-Initiative/omi-fix-dictionaries "Omi FIX Dictionaries"
[Xml.Specifications.Repository]: https://github.com/Open-Markets-Initiative/omi-xml-specifications "Omi Xml Specifications"
