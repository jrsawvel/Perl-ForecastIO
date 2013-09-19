# ForecastIO.pm

This Perl wrapper API is used to process the excellent weather data, provided in JSON format by [forecast.io](http://forecast.io/).

Related: [forecast.io developer API info](https://developer.forecast.io). From the forecast.io website:

> *"The easiest, most advanced, weather API on the web. The same API that powers Forecast.io and Dark Sky for iOS can provide accurate short­term and long­term weather predictions to your business, application, or crazy idea."*

A working example that uses this Perl module can be found at [Toledo Weather](http://toledotalk.com/weather). This weather Web app uses jQuery mobile on the client side. Several Perl scripts execute at different intervals in cron that fetch RSS, custom XML, and HTML files from the National Weather Service to provide the data for display. The [forecast.io section](http://toledotalk.com/weather/html/forecastio.html) of this Web app uses a small part of this Perl module. Code for the entire Toledo weather Web app exists on GitHub at [ToledoWX](https://github.com/jrsawvel/ToledoWX).



## Perl Module

This ForecastIO.pm Perl module was inspired by the PHP forecast.io wrapper located at [tobias-redmann/forecast.io-php-api](https://github.com/tobias-redmann/forecast.io-php-api).



## Usage

View the [test Perl script](https://github.com/jrsawvel/Perl-ForecastIO/blob/master/bin/test-forecastio-1.pl) in the bin directory.

Also, view the [output file](https://github.com/jrsawvel/Perl-ForecastIO/blob/master/data/toledo-10jul2013-output.txt), created by the above test script.


Include the module in your program.

```
use ForecastIO;
```

Create the forecast object and set API key and location.

```
my $forecast = ForecastIO->new($api_key, $latitude, $longitude);
```

Download JSON data and convert it to a Perl hash.

```
$forecast->fetch_data;
```



## Alerts

Forecast.io data includes special weather statements, watches, and warnings that have been issued by the National Weather Service, such as Severe Thunderstorm Warning, Heat Advisory, etc.

    my @alerts = $forecast->alerts;
    if ( @alerts ) {  
        foreach my $a ( @alerts ) {  
            # loop through the array of objects and 
            # use get methods to process data for 
            # each object $a in the array. Example:
            print "alert description = " . $a->alert_description . "\n";  
        }  
    }  

Get methods:

```
$a->alert_title  
$a->alert_uri  
$a->alert_expires  
$a->alert_description  
```



## Current Conditions

Get the object for the current conditions.

```
my $currently      = $forecast->currently;
```

Get methods available for the currently object:

```
$currently->time  
$currently->summary  
$currently->icon  
$currently->temperature  
$currently->dewPoint  
$currently->windBearing  
$currently->windSpeed  
$currently->pressure  
$currently->humidity  
$currently->ozone  
$currently->precipProbability  
$currently->cloudCover  
$currently->cloudCover  
$currently->precipIntensity  
$currently->precipType  
$currently->visibility  
```



## Forecast - Next 48 Hours

Return an array of hourly objects, which contain the following forecast information for each hour up to 48 hours: time, icon, temperature, pressure, wind direction, and wind speed.

    my @hourly = $forecast->hourly;
    if ( @hourly ) {
        foreach my $h ( @hourly ) {
            print ForecastIOUtils::format_date( $h->time ) .  
            # loop through the array of objects and 
            # use get methods to process data for 
            # each object $h in the array. Example:
            print "precip type =  " . $h->precipType . "\n";
        }
    }

Get methods:

```
$h->icon  
$h->temperature  
$h->precipType  
$h->pressure  
$h->windBearing  
$h->windSpeed  
```


## Forecast - Next 60 Minutes

Return an array of minutely objects, which contain the following forecast information for each minute for the next 60 minutes: time and precipitation probability, intensity, and type.

    my @minutely = $forecast->minutely;
    if ( @minutely ) {
        foreach my $m ( @minutely ) {
            # loop through the array of objects and 
            # use get methods to process data for 
            # each object $m in the array. Example:
            print "precip type =  " . $h->precipType . "\n";
        }
    }

Get methods:

```
$m->time  
$m->precipProbability  
$m->precipIntensity  
$m->precipType  
```


## Forecast - Next 7 Days

Return an array of ``daily`` objects, which contain the following forecast information for each day for the next seven days: time, sunrise time, sunset time, cloud cover, min temp and min temp time, max temp and max temp time, wind speed, wind direction, and precipitation type, max intensity, and max intensity time.

    my @daily = $forecast->daily;
    if ( @daily ) {
        foreach my $d ( @daily ) {
            # loop through the array of objects and 
            # use get methods to process data for 
            # each object $d in the array. Example:
            print "precip accumulation = " . $d->precipAccumulation . "\n";
        }
    }

Get methods 

```
$d->time  
$d->icon  
$d->sunriseTime  
$d->sunsetTime  
$d->cloudCover  
$d->precipType  
$d->precipIntensityMax  
$d->precipIntensityMaxTime  
$d->precipAccumulation  
$d->temperatureMin  
$d->temperatureMinTime  
$d->temperatureMax  
$d->temperatureMaxTime  
$d->windSpeed  
$d->windBearing  
```


## Additional Info

The very detailed forecast.io JSON data set contains other information.  Review the current API doc for details [https://developer.forecast.io/docs/v2](https://developer.forecast.io/docs/v2).

The ForecastIO.pm provides get methods for the ``forecast`` object to access some of this additional info:

```
$forecast->offset   #timezone offset  
$forecast->timezone  
$forecast->hourlysummary  
$forecast->dailysummary  
$forecast->minutelysummary  
```



## Utilities

I like the raw data provided by forecast.io. It provides the user or developer with options on how to display the data. Some of the forecast.io data needs additional processing or formatting to display it in a more "normal" way. This  ForecastIO.pm module also contains a utilities package.

The utilities below may apply to different blocks of data. For example, barometric pressure is available for the current conditions object (currently) and the 48 hour forecast object (hourly). Time exists for all blocks of data, so the format_date utility could be used for the get time method in all the objects.

The object could be alerts, current conditions, hourly forecast, etc., depending upon what data is available for each block of data. 

Refer to the [test perl script](https://github.com/jrsawvel/Perl-ForecastIO/blob/master/bin/test-forecastio-1.pl) and the [output from the test script](https://github.com/jrsawvel/Perl-ForecastIO/blob/master/data/toledo-10jul2013-output.txt) located in this repository. And read the [forecast.io API doc](https://developer.forecast.io/docs/v2).

Each utility subroutine is preceded by ``ForecastIOUtils::``

```
format_date($object->time)  
degrees_to_cardinal($object->windBearing)  
round($object->windSpeed)  
round($object->temperature)  
round($object->dewPoint)  
millibars_to_inches($object->pressure)  
cloud_cover_description($object->cloudCover)  
calc_intensity($currently->precipIntensity)  
calc_intensity_color($currently->precipIntensity)  
```

The module contains a meters to miles per hour conversion subroutine, but it can be ignored because the forecast.io data uses mph as the default format for wind speed.


### format_date

Forecast.io contains date and time in epoch seconds. The format_date subroutine returns info in the format as: 2013-07-10T17:57:36Z which is ISO 8601 format.

If no epoch seconds are passed to subroutine, then format_date returns the current date and time.

You can modify the format_date subroutine to produce a different format. 


### degrees to cardinal

The direction that the wind is blowing from.

The 360 degree compass data (clockwise) is converted into its text representation. So 0 degrees equals North. 90 degrees equals East. 180 degrees equals South. 270 degrees equals West.

In between data can be represented, such as WSW, which means the wind is blowing from the west-southwest.

The subroutine returns one to three uppercase letters to represent wind direction, such as NE, S, WNW.


### rounding

Some data is returned in decimal format, such as temperature and wind speed, and the subroutine will round up if necessary.


### millibars to inches

Forecast.io presents barometric pressure in millibars, so this routine converts it to inches of mercury, which is how pressure is normally displayed for general usage.


### cloud cover description

Forecast.io data returns cloud cover data in a decimal or whole number format between 0 and 1.

From the [forecast.io API doc](https://developer.forecast.io/docs/v2):

- A value of 0 corresponds to clear sky, 
- 0.4 to scattered clouds, 
- 0.75 to broken cloud cover, 
- 1 to completely overcast skies.

Refer to: [http://forecast.weather.gov/glossary.php?word=SKY%20CONDITION](http://forecast.weather.gov/glossary.php?word=SKY%20CONDITION)

In ForecastIO.pm, I established my own breakpoints and applied the above cloud cover or sky condition terms, which include clear, mostly clear, partly cloudy, mostly cloudy, and cloudy. Refer to the ForecastIO.pm module code to see the breakpoints.


### calc precip intensity

Forecast.io data returns precipitation intensity data in a decimal or whole number format between 0 and 1.

From the [forecast.io API doc](https://developer.forecast.io/docs/v2):

> precipIntensity: A numerical value representing the average expected intensity 
(in inches of liquid water per hour) of precipitation occurring at the given 
time conditional on probability (that is, assuming any precipitation occurs at all). 

- A very rough guide is that a value of 0 corresponds to no precipitation, 
- 0.002 corresponds to very light precipitation, 
- 0.017 corresponds to light precipitation, 
- 0.1 corresponds to moderate precipitation, 
- and 0.4 corresponds to very heavy precipitation.

Based upon the above forecast.io info, I established breakpoints and text representations for precip intensities in the ``calc_intensity`` subroutine, such as very light, light, light to moderate, moderate, moderate to heavy, heavy, heavy to very heavy, and very heavy.

The ``calc_intensity_color`` subroutine uses the same breakpoints, but it returns a hex color code, which, for example, can be used to display "heavy" precip intensity in dark red text color.

Play around with the precipitation intensity subroutines to produce text values and color codes that seem more appropriate with your own observations.

During the summer of 2013, I think the text-based intensity values returned in this module match my observations in Toledo, Ohio. 

In my [ToledoWX](http://toledotalk.com/weather) weather Web app, I access these precip calc intensity subroutines for the [minute by minute forecasts](http://toledotalk.com/weather/html/forecastio.html) for the next hour for three locations in the Toledo area.  When a storm moves through, it's interesting to view the minutely forecasts for each location and note which areas are forecast to receive heavier rainfall. From my observations, the minutely forecasts and precip intensities are quite accurate. It's good information. 



## Sample Code

    #!/usr/bin/perl -wT

    use strict;

    $|++;

    BEGIN {
        unshift @INC, "../lib";
    }

    use ForecastIO;

    my $api_key = "<api key>"; 
    my $latitude = "41.665556";
    my $longitude = "-83.575278";

    my $forecast = ForecastIO->new($api_key, $latitude, $longitude);

    $forecast->fetch_data;

    print "Current Weather Conditions\n";

    my $currently      = $forecast->currently;

    my $wind_direction = ForecastIOUtils::degrees_to_cardinal($currently->windBearing);
    my $wind_speed     = ForecastIOUtils::round($currently->windSpeed);
    $wind_speed        = 0 if $wind_speed eq "undef";
    $wind_direction    = "Calm wind" if $wind_speed == 0; 

    print "         date and time = " . ForecastIOUtils::format_date($currently->time) . "\n"; 
    print "               summary = " . $currently->summary . "\n";
    print "                  icon = " . $currently->icon . "\n";
    print "              air temp = " . ForecastIOUtils::round($currently->temperature) . "\n";
    print "             dew point = " . ForecastIOUtils::round($currently->dewPoint) . "\n";
    print "         wind directon = " . $wind_direction . "\n";
    print "            wind speed = " . $wind_speed . " mph\n";
    print "              pressure = " . ForecastIOUtils::millibars_to_inches($currently->pressure) . " in. " . "\n";
    print "              humidity = " . $currently->humidity * 100 . "% \n";
    print "                 ozone = " . $currently->ozone . " Dobson units\n";
    print "           precip prob = " . $currently->precipProbability * 100 . "% \n";
    print "           cloud cover = " . $currently->cloudCover * 100 . "%\n";
    print "      cloud cover desc = " . ForecastIOUtils::cloud_cover_description($currently->cloudCover) . "\n";
    print "      precip intensity = " . $currently->precipIntensity . "\n";
    print " precip intensity desc = " . ForecastIOUtils::calc_intensity($currently->precipIntensity) . "\n";
    print "precip intensity color = " . ForecastIOUtils::calc_intensity_color($currently->precipIntensity) . "\n";
    print "           precip type = " . $currently->precipType . "\n";
    print "            visibility = " . $currently->visibility . " miles\n";




## Sample Output

Output from the above code:

<pre>
Current Weather Conditions
         date and time = 2013-07-10T17:57:36Z
               summary = Light Rain
                  icon = rain
              air temp = 86
             dew point = 75
         wind directon = WSW
            wind speed = 9 mph
              pressure = 29.81 in. 
              humidity = 70% 
                 ozone = 296.55 Dobson units
           precip prob = 100% 
           cloud cover = 40%
      cloud cover desc = partly cloudy
      precip intensity = 0.046
 precip intensity desc = light
precip intensity color = #888888;
           precip type = rain
            visibility = 9.84 miles
</pre>



## Additional Methods

### test data

If you download and save the JSON data set for testing, you can specify a URL to this test data set, located on your own server.

Use the ``api_url`` method to point the module to the location of your stored JSON data.

    use ForecastIO;

    my $api_key = "<api key>";
    my $latitude = "41.665556";
    my $longitude = "-83.575278";

    my $forecast = ForecastIO->new($api_key, $latitude, $longitude);
   
    $forecast->api_url("http://testurl/saveddata.json");

    $forecast->fetch_data;

    my $currently      = $forecast->currently;

    # proceed as normal from here


### access old weather data

The forecast.io API allows you to access old weather data for the location specified, which can be interesting.

Instead of using the normal ``fetch_data`` method, use ``fetch_data_for_date`` and specify a date and time in the ISO 8601 format.

    use ForecastIO;

    my $api_key = "<api key>";
    my $latitude = "41.665556";
    my $longitude = "-83.575278";

    my $forecast = ForecastIO->new($api_key, $latitude, $longitude);

    $forecast->fetch_data_for_date("2012-07-11T12:00:00-0400");

    my $currently      = $forecast->currently;

    # proceed as normal from here

