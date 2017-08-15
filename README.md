#OpenWeatherApp

##Solution Manual

After launch user able to see weather forecast for current location (User will be asked to allow application to track location) . 

User can see forecasts grouped by days.

Pull to refresh available to update forecast table.

**‘Add’** button at right part of navigation bar leads to Region selection screen.

User able to see current location region marked by blue marker, can add new regions by long touch on desirable location, or can select existed region by tapping on it’s marker.

At callout view of selected region user able to see icon of nearest forecast. Also user able to remove region information from app. User can’t remove current region. 

Back button navigate to details of selected region.  If no region was selected, current region will be requested.

##Imlementation details

DataRetrivalManager responsible for handling all application specific data. It use operation chain to fetch and process data from network.

Each operation had limited responsibilities.

As all operations had to be initialized at once, before completion of others dependent operations, accumulator buffers used to share information and data between them.

##Unit tests

Application supplied with unit tests to cover data requesting and parsing. 

No UI tests provided because  of limited capabilities to test MapKit and tableview/collection views.

As 3rd party frameworks forbidden, no http mocking done. All tests performed on real network so they network tests will fail offline. OHHTTPStubs recommended to support proper network test coverage.
