# DBConnect

This Swift package offers a simple way to interact with various on-board train APIs!
It was initially developed to power [ICE Buddy](https://ice-buddy.riedel.wtf) and is now being expanded for [Train Buddy](https://github.com/mel1na/ICE-Buddy-macOS), a fork of ICE Buddy.

## Support:
This package currently supports three train operator APIs:
- DB: ICE
- ÖBB: Railjet (1st generation)
- SNCF: TGV

### Pending info
The following APIs have planned support, but are missing example data:
- DB: Regional trains?
- ÖBB: Railjet (2nd generation), Nightjet (1st and 2nd generation), S-Bahn
- SBB: ECs with on-board WiFi, ECE

If you have information about any of these and want to help, please open an issue!

### Available Data Points
- Current speed (km/h)
- Train name and journey title (e.g., ICE 643: Düsseldorf Hbf -> Berlin Ostbahnhof)
- Train model (e.g., ICE 4) (DB/SNCF)
- Train model image
- Journey (all train stations), incluing:
    - Track
    - Planned arrival time
    - Actual arrival time (delay)
- Current internet quality (stable / unstable) (DB/SNCF)
     


## My local train is not supported!
Feel free to open an issue with more information about what data the WiFi provides or create a pull request :)
